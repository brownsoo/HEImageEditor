//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/23/24.
//

import Foundation
import UIKit

public protocol HEImageCache: AnyObject {
//    func cacheImage(_ image: UIImage, forId id: String) -> Void
//    func getCachedImage(forId id: String) -> UIImage?
    
    func originImage(hei: HEImage) -> Task<UIImage, Error>
    func editImage(forHei hei: HEImage) -> Task<UIImage, Error>
//    func thumbnailImage(forHei hei: HEImage) -> Task<UIImage, Error>
    
    func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error>
    func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error>
    
    func clearCached(forHei hei: HEImage) async
}

@MainActor
public protocol HEImageDataStore: AnyObject {
    func addHEImage(_ hei: HEImage, excepting: ((HEImage) -> Bool)?)
    func addHEImages(_ heis: [HEImage], excepting: ((HEImage) -> Bool)?)
    func addImage(image: UIImage)
    func addImage(url: URL)
    
    func removeHEImage(_ he: HEImage)
    func clearAll()
    
    func all() -> [HEImage]
    func numberOfImages() -> Int
    func getHEImage(at index: Int) -> HEImage?
    func getHEImage(forId id: String) -> HEImage?
}

public extension HEImageDataStore {
    func addHEImage(_ hei: HEImage) {
        self.addHEImage(hei, excepting: nil)
    }
    func addHEImages(_ heis: [HEImage]) {
        self.addHEImages(heis, excepting: nil)
    }
}

public class HESimpleImageStore: HEImageDataStore {
    
    public init(){}
    
    let memCache = NSCache<AnyObject, AnyObject>()
    let thumbCache = NSCache<AnyObject, AnyObject>()
    var images: [HEImage] = []
    
    public func removeHEImage(_ he: HEImage) {
        images.removeAll(where: { $0.id == he.id })
    }
    
    public func clearAll() {
        images.removeAll()
    }
    
    
    public func addHEImage(_ hei: HEImage, excepting: ((HEImage) -> Bool)?) {
        if let excepting {
            if images.first(where: excepting) == nil {
                images.append(hei)
            }
        } else {
            images.append(hei)
        }
    }
    
    public func addHEImages(_ heis: [HEImage], excepting: ((HEImage) -> Bool)?) {
        if let excepting {
            var exists = images
            heis.forEach { hei in
                if exists.first(where: excepting) == nil {
                    images.append(hei)
                }
            }
        } else {
            images.append(contentsOf: heis)
        }
    }
    
    public func addImage(image: UIImage) {
        images.append(HEImage(image: image, editModel: nil))
    }
    
    public func addImage(url: URL) {
        images.append(HEImage(origin: url, editModel: nil))
    }
    
    public func all() -> [HEImage] {
        images
    }
    
    public func numberOfImages() -> Int {
        images.count
    }
    
    public func getHEImage(at index: Int) -> HEImage? {
        if index < images.count {
            return images[index]
        }
        return nil
    }
    
    public func getHEImage(forId id: String) -> HEImage? {
        images.first(where: { $0.id == id })
    }
}

extension HESimpleImageStore: HEImageCache {
    private func cacheImage(_ image: UIImage, forId id: String) {
        memCache.setObject(image, forKey: id as AnyObject)
    }
    
    private func getCachedImage(forId id: String) -> UIImage? {
        memCache.object(forKey: id as AnyObject) as? UIImage
    }
    
    public func originImage(hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let originImage = hei.originImage {
                return originImage
            }
            guard let originURL = hei.originURL else {
                throw HEError.imageNotFound
            }
            return try await getImage(forURL: originURL, heiId: hei.id).value
        }
    }
    
    
    public func editImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let editImageURL = await hei.editImageURL {
                return try await getImage(forURL: editImageURL, heiId: hei.id).value
            } else {
                return try await originImage(hei: hei).value
            }
        }
    }
    
    public func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error> {
        let fileName = hei.id + ".png"
        return Task {
            guard let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            cacheImage(uiImage, forId: hei.id)
            
            await hei.setEditImageURL(fileURL)
            
            return fileURL
        }
    }
    
    public func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error> {
        let fileName = hei.id + ".thumb.png"
        return Task {
            guard let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await hei.setThumbnailURL(fileURL)
            
            return fileURL
        }
    }
    
    public func clearCached(forHei hei: HEImage) async {
        await hei.setEditImageURL(nil)
        await hei.setThumbnailURL(nil)
        do {
            let fileURL = try fileURL(fileName: hei.id + ".png")
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            woops(error)
        }
        do {
            let fileURL = try fileURL(fileName: hei.id + ".thumb.png")
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            woops(error)
        }
    }
}

extension HESimpleImageStore {
    
    func fileURL(fileName: String) throws -> URL {
        let dir = directoryURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if #available(iOS 16.0, *) {
            return dir.appending(path: fileName, directoryHint: .notDirectory)
        } else {
            return dir.appendingPathComponent(fileName, isDirectory: false)
        }
    }
    
    func directoryURL() -> URL {
        if #available(iOS 16.0, *) {
            return FileManager.default.temporaryDirectory.appending(path: "he", directoryHint: .isDirectory)
        } else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("he", isDirectory: true)
        }
    }
    
    func getImage(forURL url: URL , heiId id: String) -> Task<UIImage, Error> {
        Task {
            if let cached = getCachedImage(forId: id) {
                return cached
            }
            
            if url.isFileURL {
                let image = try await Task.detached {
                    let data = try Data(contentsOf: url)
                    return UIImage(data: data)!
                }.value
                return image
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            trace(response)
            if let image = UIImage(data: data) {
                cacheImage(image, forId: id)
                return image
            }
            
            throw HEError.imageNotFound
        }
    }
    
    
}
