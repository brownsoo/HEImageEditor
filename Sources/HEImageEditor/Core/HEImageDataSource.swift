//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/23/24.
//

import Foundation
import UIKit

public protocol HEImageCache: AnyObject {
    func cacheImage(_ image: UIImage, forId id: String) -> Void
    
    func getCachedImage(forId id: String) -> UIImage?
    
    func originImage(hei: HEImage) -> Task<UIImage, Error>
    func editImage(forHei hei: HEImage) -> Task<UIImage, Error>
    func storeEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error>
}

@MainActor
public protocol HEImageDataSource: AnyObject {
    func removeHEImage(_ he: HEImage)
    func addHEImage(_ he: HEImage)
    func addHEImages(_ hes: [HEImage])
    func addImage(image: UIImage)
    func addImage(url: URL)
    
    func numberOfImages() -> Int
    func imageStore(at index: Int) -> HEImage?
    func imageStore(forId id: String) -> HEImage?
    
}

public class HESimpleImageStore: HEImageDataSource {
    public lazy var shared: HESimpleImageStore = {
        return HESimpleImageStore()
    }()
    
    init(){}
    
    let imageCache = NSCache<AnyObject, AnyObject>()
    var images: [HEImage] = []
    
    public func removeHEImage(_ he: HEImage) {
        images.removeAll(where: { $0.id == he.id })
    }
    
    public func addHEImage(_ he: HEImage) {
        images.append(he)
    }
    
    public func addHEImages(_ hes: [HEImage]) {
        images.append(contentsOf: hes)
    }
    
    public func addImage(image: UIImage) {
        images.append(HEImage(image: image, editModel: nil))
    }
    
    public func addImage(url: URL) {
        images.append(HEImage(origin: url, editModel: nil))
    }
    
    public func numberOfImages() -> Int {
        images.count
    }
    
    public func imageStore(at index: Int) -> HEImage? {
        if index < images.count {
            return images[index]
        }
        return nil
    }
    
    public func imageStore(forId id: String) -> HEImage? {
        images.first(where: { $0.id == id })
    }
}

extension HESimpleImageStore: HEImageCache {
    public func cacheImage(_ image: UIImage, forId id: String) {
        imageCache.setObject(image, forKey: id as AnyObject)
    }
    
    public func getCachedImage(forId id: String) -> UIImage? {
        imageCache.object(forKey: id as AnyObject) as? UIImage
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
    
    public func storeEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL?, Error> {
        let dir = directoryURL()
        let fileName = hei.id + ".png"
        return Task {
            guard let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            let fileURL: URL
            if #available(iOS 16.0, *) {
                fileURL = dir.appending(path: fileName, directoryHint: .notDirectory)
            } else {
                fileURL = dir.appendingPathComponent(fileName, isDirectory: false)
            }
            
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            cacheImage(uiImage, forId: hei.id)
            
            await hei.setEditImageURL(fileURL)
            
            return fileURL
        }
    }
}

extension HESimpleImageStore {
    
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
            if let image = UIImage(data: data) {
                cacheImage(image, forId: id)
                return image
            }
            
            throw HEError.imageNotFound
        }
    }
    
    
}
