//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/23/24.
//

import Foundation
import UIKit

public protocol HEImageCache: AnyObject {
    
    /// 원본 이미지 캐시
    func cacheOriginImage(uiImage: UIImage, forId id: String) -> Task<URL, Error>
    func cacheOriginImageSync(uiImage: UIImage, forId id: String) throws -> URL
    /// 편집 이미지 캐시
    func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error>
    /// 썸네일 이미지 캐시
    func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error>
    
    /// 원본 이미지
    func originImage(forHei hei: HEImage) -> Task<UIImage, Error>
    func originImageSync(forHei hei: HEImage) throws -> UIImage?
    /// 편집 이미지
    func editImage(forHei hei: HEImage) -> Task<UIImage, Error>
    func editImageSync(forHei hei: HEImage) throws -> UIImage?
    /// 썸네일 이미지
    func thumbnailImage(forHei hei: HEImage) -> Task<UIImage, Error>
    func thumbnailImageSync(forHei hei: HEImage) throws -> UIImage?
    
    
    /// 캐시된 URL 값만 확인
    func getCachedOriginImageURL(forId id: String) throws -> URL?
    /// 캐시된 URL 값만 확인
    func getCachedEditImageURL(forId id: String) throws -> URL?
    
    
    func clearCached(forHei hei: HEImage, includeOrigin: Bool) async
}

@MainActor
public protocol HEImageDataStore: AnyObject {
    func addHEImage(_ hei: HEImage, excepting: ((HEImage) -> Bool)?)
    func addHEImages(_ heis: [HEImage], excepting: ((HEImage) -> Bool)?)
    
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

public extension String {
    func toHEImageCacheIdentifier() -> String {
        return self.replacingOccurrences(of: "/", with: "~")
    }
    
    func fromHEImageCacheIdentifier() -> String {
        return self.replacingOccurrences(of: "~", with: "/")
    }
}


public protocol HEEditImageStore: HEImageDataStore, HEImageCache {}

/// 간단히 구현된 편집용 이미지 스토어
public class HESimpleEditImageStore: HEEditImageStore {
    
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
            let exists = images
            heis.forEach { hei in
                if exists.first(where: excepting) == nil {
                    images.append(hei)
                }
            }
        } else {
            images.append(contentsOf: heis)
        }
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

// MARK: HEImageCache
extension HESimpleEditImageStore {
    private func memCacheImage(_ image: UIImage, forUrl url: String) {
        memCache.setObject(image, forKey: url as AnyObject)
    }
    
    private func getMemCachedImage(forUrl url: String) -> UIImage? {
        let cached = memCache.object(forKey: url as AnyObject) as? UIImage
        trace(cached != nil)
        return cached
    }
    
    public func originImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let originImage = hei.originImage {
                return originImage
            }
            guard let originURL = hei.originURL else {
                throw HEError.imageNotFound
            }
            return try await getImage(forURL: originURL).value
        }
    }
    
    
    public func editImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let editImageURL = hei.editImageURL {
                return try await getImage(forURL: editImageURL).value
            } else {
                return try await originImage(forHei: hei).value
            }
        }
    }
    
    public func thumbnailImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let thumbnailURL = hei.thumbnailURL {
                return try await getImage(forURL: thumbnailURL).value
            } else {
                throw HEError.imageNotFound
            }
        }
    }
    
    public func originImageSync(forHei hei: HEImage) throws -> UIImage? {
        if let originImage = hei.originImage {
            return originImage
        }
        guard let originURL = hei.originURL else {
            throw HEError.imageNotFound
        }
        return try getImageSync(forURL: originURL)
    }
    
    public func editImageSync(forHei hei: HEImage) throws -> UIImage? {
        if let editImageURL = hei.editImageURL {
            return try getImageSync(forURL: editImageURL)
        } else {
            return try originImageSync(forHei: hei)
        }
    }
    
    public func thumbnailImageSync(forHei hei: HEImage) throws -> UIImage? {
        if let thumbnailURL = hei.thumbnailURL {
            return try getImageSync(forURL: thumbnailURL)
        } else {
            throw HEError.imageNotFound
        }
    }
    
    public func getCachedOriginImageURL(forId id: String) throws -> URL? {
        let fileName = id.toHEImageCacheIdentifier() + ".png"
        let fileURL: URL = try fileURL(fileName: fileName)
        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            return fileURL
        }
        return nil
    }
    
    public func getCachedEditImageURL(forId id: String) throws -> URL? {
        let fileName = id.toHEImageCacheIdentifier() + ".edit.png"
        let fileURL: URL = try fileURL(fileName: fileName)
        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            return fileURL
        }
        return nil
    }
    
    public func cacheOriginImage(uiImage: UIImage, forId id: String) -> Task<URL, Error> {
        let fileName = id.toHEImageCacheIdentifier() + ".png"
        return Task.detached { [weak self] in
            guard let self, let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try await fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await memCacheImage(uiImage, forUrl: fileName)
            trace(fileURL)
            return fileURL
        }
    }
    
    public func cacheOriginImageSync(uiImage: UIImage, forId id: String) throws -> URL {
        let fileName = id.toHEImageCacheIdentifier() + ".png"
        guard let data = uiImage.pngData() else {
            throw HEError.generateFileData
        }
        let fileURL: URL = try fileURL(fileName: fileName)
        FileManager.default.createFile(atPath: fileURL.path, contents: data)
        Task.detached { [weak self] in
            await self?.memCacheImage(uiImage, forUrl: fileName)
        }
        trace(fileURL)
        return fileURL
    }
    
    public func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error> {
        let fileName = hei.id.toHEImageCacheIdentifier() + ".edit.png"
        return Task.detached { [weak self] in
            guard let self, let data = uiImage.pngData() else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try await fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await memCacheImage(uiImage, forUrl: fileName)
            await hei.setEditImageURL(fileURL)
            
            return fileURL
        }
    }
    
    public func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error> {
        let fileName = hei.id.toHEImageCacheIdentifier() + ".thumb.png"
        return Task.detached { [weak self] in
            let thumbnail = uiImage.he.thumbnail()
            guard let self, let data = thumbnail.pngData() else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try await fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await memCacheImage(uiImage, forUrl: fileName)
            await hei.setThumbnailURL(fileURL)
            
            return fileURL
        }
    }
    
    public func clearCached(forHei hei: HEImage, includeOrigin: Bool) async {
        if includeOrigin {
            if let originURL = hei.originURL {
                memCache.removeObject(forKey: originURL.absoluteString as AnyObject)
            }
        }
        
        if let editImageURL = hei.editImageURL {
            memCache.removeObject(forKey: editImageURL.absoluteString as AnyObject)
        }
        if let thumbnailURL = hei.thumbnailURL {
            memCache.removeObject(forKey: thumbnailURL.absoluteString as AnyObject)
        }
        
        
        hei.setEditImageURL(nil)
        hei.setThumbnailURL(nil)
        
        let editFileURL = try? fileURL(fileName: hei.id.toHEImageCacheIdentifier() + ".edit.png")
        let thumbFileURL = try? fileURL(fileName: hei.id.toHEImageCacheIdentifier() + ".thumb.png")
        Task.detached {
            do {
                if let editFileURL {
                    try FileManager.default.removeItem(at: editFileURL)
                }
            } catch {
                woops(error)
            }
            do {
                if let thumbFileURL {
                    try FileManager.default.removeItem(at: thumbFileURL)
                }
            } catch {
                woops(error)
            }
        }
    }
}

extension HESimpleEditImageStore {
    
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
    
    func getImage(forURL url: URL) -> Task<UIImage, Error> {
        Task.detached { [weak self] in
            if let cached = await self?.getMemCachedImage(forUrl: url.absoluteString) {
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
                await self?.memCacheImage(image, forUrl: url.absoluteString)
                return image
            }
            
            throw HEError.imageNotFound
        }
    }
    
    func getImageSync(forURL url: URL) throws -> UIImage? {
        if let cached = getMemCachedImage(forUrl: url.absoluteString) {
            return cached
        }
        if url.isFileURL {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)!
        }
        // TODO: download remove image?
//        let (data, response) = try await URLSession.shared.data(from: url)
//        trace(response)
//        if let image = UIImage(data: data) {
//            self.memCacheImage(image, forUrl: url.absoluteString)
//            return image
//        }
        
        throw HEError.imageNotFound
    }
    
}
