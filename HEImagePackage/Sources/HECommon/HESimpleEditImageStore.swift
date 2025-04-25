//
//  HESimpleEditImageStore.swift
//  HEImageEditor
//
//  Created by hyonsoo on 10/19/24.
//
import Foundation
import Kingfisher
import UIKit
import ImageIO

public extension String {
    func toHEImageCacheIdentifier() -> String {
        return self.replacingOccurrences(of: "/", with: "~")
    }
    
    func fromHEImageCacheIdentifier() -> String {
        return self.replacingOccurrences(of: "~", with: "/")
    }
    
    func heImageCacheEditFileName(date: Date = Date()) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "_yyMMdd_HHmmss"
        let timeString = dateFormatter.string(from: date)
        return self.toHEImageCacheIdentifier() + timeString + "+edit.jpg"
    }
    
    func heImageCacheFattenFileName(date: Date = Date()) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "_yyMMdd_HHmmss"
        let timeString = dateFormatter.string(from: date)
        return self.toHEImageCacheIdentifier() + timeString + "+fatten.jpg"
    }
    
    func heImageCacheThumbFileName(date: Date = Date()) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "_yyMMdd_HHmmss"
        let timeString = dateFormatter.string(from: date)
        return self.toHEImageCacheIdentifier() + timeString + "+thumb.jpg"
    }
}



public protocol HEEditImageStore: AnyObject, HEImageDataStore, HEImageCache {}

/// 간단히 구현된 편집용 이미지 스토어
public class HESimpleEditImageStore: HEEditImageStore {
    
    
    public static func fileURL(fileName: String) throws -> URL {
        let dir = directoryURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if #available(iOS 16.0, *) {
            return dir.appending(path: fileName, directoryHint: .notDirectory)
        } else {
            return dir.appendingPathComponent(fileName, isDirectory: false)
        }
    }
    
    public static func directoryURL() -> URL {
        if #available(iOS 16.0, *) {
            return FileManager.default.temporaryDirectory.appending(path: "he", directoryHint: .isDirectory)
        } else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("he", isDirectory: true)
        }
    }

    public init(){}
    
    let memCache = NSCache<NSString, UIImage>()
    let thumbCache = NSCache<NSString, UIImage>()
    var images: [HEImage] = []
    
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
    
    
    public func removeHEImage(_ id: String) {
        images.removeAll(where: { $0.id == id })
    }
    
    public func removeHEImage(_ he: HEImage) {
        images.removeAll(where: { $0.id == he.id })
    }
    
    public func clearAll() {
        images.removeAll()
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
    
    public func getHEImage(forAssetIdentifier identifier: String) -> HEImage? {
        images.first(where: { ($0.phAssetIdentifier ?? $0.id) == identifier })
    }
    
    public func replaceHEImage(_ exist: HEImage, with item: HEImage) -> Bool {
        if let index = images.firstIndex(where: { $0.id == exist.id }) {
            return replaceHEImage(at: index, with: item)
        }
        return false
    }
    
    public func replaceHEImage(at index: Int, with item: HEImage) -> Bool {
        if index < images.count {
            images[index] = item
            return true
        }
        return false
    }
    
    public func sorts(byIds ids: [String]) {
        var news = self.images
        news.sort { a, b in
            if let ai = ids.firstIndex(where: { a.id == $0 }),
               let bi = ids.firstIndex(where: { b.id == $0 }) {
                return ai < bi
            }
            return false
        }
        self.images = news
    }
}

// MARK: Caching -

extension HESimpleEditImageStore {
    
    public func cacheOriginImage(uiImage: UIImage, forId id: String, isGif: Bool) async throws -> URL {
        if isGif, let data = uiImage.he.gifData() {
            return try await cacheOriginImage(imageData: data, forId: id, isGif: true)
        } else if let data = uiImage.he.fixOrientation().jpegData(compressionQuality: 0.8) {
            return try await cacheOriginImage(imageData: data, forId: id, isGif: false)
        } else {
            throw HEError.generateFileData
        }
    }
    
    public func cacheOriginImage(imageData: Data, forId id: String, isGif: Bool) async throws -> URL {
        let fileName = id.toHEImageCacheIdentifier() + (isGif ? ".gif" : ".jpg")
        let fileURL: URL = try Self.fileURL(fileName: fileName)
        FileManager.default.createFile(atPath: fileURL.path, contents: imageData)
        
        lg.trace(imageData.he.fileSizeInKB)
        
        if isGif {
            // gif 메모리 캐시 제거
//            guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
//                woops("image doesn't exist")
//                return fileURL
//            }
//            Task.detached { [weak self] in
//                if let uiImage = UIImage.animatedImage(with: source) {
//                    await self?.memCacheImage(uiImage, forUrl: fileURL)
//                }
//            }
        } else {
            Task.detached { [weak self] in
                if let uiImage = UIImage(data: imageData) {
                    await self?.memCacheImage(uiImage, forUrl: fileURL)
                }
            }
        }
        
        return fileURL
    }
    
    public func cacheFattenImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL {
        return try await Task.detached { [weak self] in
            guard let self, let data = uiImage.jpegData(compressionQuality: 0.8) else {
                throw HEError.generateFileData
            }
            let url = try await self.cacheSomeImage(imageData: data, forHei: hei,
                                                    fileName: hei.id.heImageCacheFattenFileName())
            hei.setFattenImageURL(url)
            return url
        }.value
    }
    
    public func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL {
        return try await Task.detached { [weak self] in
            guard let self, let data = uiImage.jpegData(compressionQuality: 0.8) else {
                throw HEError.generateFileData
            }
            let url = try await self.cacheSomeImage(imageData: data, forHei: hei,
                                                    fileName: hei.id.heImageCacheEditFileName())
            hei.setEditImageURL(url)
            return url
        }.value
    }
    
    
    public func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL {
        return try await Task.detached { [weak self] in
            guard let self, let data = uiImage.jpegData(compressionQuality: 0.8) else {
                throw HEError.generateFileData
            }
            let url = try await self.cacheSomeImage(imageData: data, forHei: hei,
                                                    fileName: hei.id.heImageCacheThumbFileName())
            hei.setThumbnailURL(url)
            return url
        }.value
    }
    
    internal func cacheSomeImage(imageData: Data, forHei hei: HEImage, fileName: String) async throws -> URL {
        let fileURL: URL = try Self.fileURL(fileName: fileName)
        let success = FileManager.default.createFile(atPath: fileURL.path, contents: imageData)
        if !success {
            throw HEError.generateFileData
        }
#if DEBUG
        lg.trace(imageData.he.fileSizeInKB)
#endif
        Task.detached { [weak self] in
            if let uiImage = UIImage(data: imageData) {
                await self?.memCacheImage(uiImage, forUrl: fileURL)
            }
        }
        return fileURL
    }
    
   
    // MARK: Get images
   
    public func originImage(forHei hei: HEImage) async throws -> UIImage {
        if let originImage = hei.originImage {
            return originImage
        }
        guard let url = hei.originURL else {
            throw HEError.imageNotFound
        }
        return try getImage(forURL: url)
    }
    
    public func fattenImage(forHei hei: HEImage) async throws -> UIImage {
        if let url = hei.fattenImageURL {
            return try getImage(forURL: url)
        } else {
            return try await originImage(forHei: hei)
        }
    }
    
    public func editImage(forHei hei: HEImage) async throws -> UIImage {
        if let url = hei.editImageURL {
            return try getImage(forURL: url)
        } else {
            return try await originImage(forHei: hei)
        }
    }
    
    public func thumbnailImage(forHei hei: HEImage) async throws -> UIImage {
        if let url = hei.thumbnailURL {
            return try getImage(forURL: url)
        } else {
            throw HEError.imageNotFound
        }
    }
    
    public func clearCached(forHei hei: HEImage, includeOrigin: Bool) async {
        if includeOrigin {
            if let originURL = hei.originURL {
                clearMemCachedImage(forUrl: originURL)
            }
        }
        
        if let editImageURL = hei.editImageURL {
            clearMemCachedImage(forUrl: editImageURL)
            removeFile(editImageURL)
        }
        if let fattenImageURL = hei.fattenImageURL {
            clearMemCachedImage(forUrl: fattenImageURL)
            removeFile(fattenImageURL)
        }
        if let thumbnailURL = hei.thumbnailURL {
            clearMemCachedImage(forUrl: thumbnailURL)
            removeFile(thumbnailURL)
        }
        hei.resetToOrigin()
    }
    
    public func clearAllCachedFiles() async {
        do {
            try FileManager.default.removeItem(at: Self.directoryURL())
            memCache.removeAllObjects()
            lg.trace()
        } catch {
            lg.woops(error)
        }
    }
}

extension HESimpleEditImageStore {
    
    func removeFile(_ fileURL: URL) {
        Task.detached {
            do {
                try FileManager.default.removeItem(at: fileURL)
                lg.trace("removeFile - \(fileURL.absoluteString)")
            } catch {
                lg.woops(error)
            }
        }
    }
    
    func memCacheImage(_ image: UIImage, forUrl url: URL) async {
        memCache.setObject(image, forKey: NSString(string: url.absoluteString))
    }
    
    func getMemCachedImage(forUrl url: URL) -> UIImage? {
        return memCache.object(forKey: NSString(string: url.absoluteString))
    }
    
    func clearMemCachedImage(forUrl url: URL) {
        memCache.removeObject(forKey: NSString(string: url.absoluteString))
    }
    
    func getImage(forURL url: URL) -> Task<UIImage, Error> {
        Task.detached { [weak self] in
            if let cached = self?.getMemCachedImage(forUrl: url) {
                return cached
            }
            
            if url.isFileURL {
                let image = try await Task.detached {
                    let data = try Data(contentsOf: url)
                    return UIImage(data: data)!
                }.value
                return image
            }
            
            let remoteImage = await HERemoteImageDownloader().download(url)
            if let image = remoteImage {
                await self?.memCacheImage(image, forUrl: url)
                return image
            }
            
            throw HEError.imageNotFound
        }
    }
    
    func getImage(forURL url: URL) throws -> UIImage {
        if let cached = getMemCachedImage(forUrl: url) {
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


final class HERemoteImageDownloader {
    func download(_ url: URL) async -> UIImage? {
        await withUnsafeContinuation { continuation in
            ImageDownloader.default.downloadImage(with: url) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value.image.withRenderingMode(.alwaysOriginal))
                case .failure(let error):
                    lg.woops(error)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
