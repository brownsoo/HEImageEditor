//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/23/24.
//

import Foundation
import Kingfisher
import UIKit
import ImageIO

public protocol HEImageCache: AnyObject {
    
    /// 원본 이미지 캐시
    @available(*, deprecated, message: "GIF 측정이 부정확")
    func cacheOriginImage(uiImage: UIImage, forId id: String) -> Task<URL, Error>
    func cacheOriginImage(uiImage: UIImage, forId id: String, isGif: Bool) -> Task<URL, Error>
    /// 원본 이미지 캐시
    @available(*, deprecated, message: "GIF 측정이 부정확")
    func cacheOriginImageSync(uiImage: UIImage, forId id: String) throws -> URL
    func cacheOriginImageSync(uiImage: UIImage, forId id: String, isGif: Bool) throws -> URL
    /// 원본 이미지 캐시
    func cacheOriginImage(imageData: Data, forId id: String, isGif: Bool) -> Task<URL, Error>
    /// 원본 이미지 캐시
    func cacheOriginImageSync(imageData: Data, forId id: String, isGif: Bool) throws -> URL
    
    
    /// 편집 이미지 캐시
    func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error>
    /// 중간 정리된 이미지 캐시
    func cacheFattenImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error>
    /// 중간 정리된 이미지 캐시
    func cacheFattenImageSync(uiImage: UIImage, forHei hei: HEImage) throws -> URL
    func cacheFattenImageSync(imageData: Data, forHei hei: HEImage) throws -> URL
    /// 썸네일 이미지 캐시
    func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error>
    
    /// 원본 이미지
    func originImage(forHei hei: HEImage) -> Task<UIImage, Error>
    /// 원본 이미지
    func originImageSync(forHei hei: HEImage) throws -> UIImage?
    /// 중간 이미지 or 원본 이미지
    func fattenImage(forHei hei: HEImage) -> Task<UIImage, Error>
    /// 편집 이미지 or 원본 이미지
    func editImage(forHei hei: HEImage) -> Task<UIImage, Error>
    /// 편집 이미지 or 원본 이미지
    func editImageSync(forHei hei: HEImage) throws -> UIImage?
    /// 썸네일 이미지
    func thumbnailImage(forHei hei: HEImage) -> Task<UIImage, Error>
    /// 썸네일 이미지
    func thumbnailImageSync(forHei hei: HEImage) throws -> UIImage?
    
    
    /// 캐시된 URL 값만 확인
//    @available(*, deprecated, message: "원본 경로를 id 로 측정하는 데 문제가 있음")
//    func getCachedOriginImageURL(forId id: String) throws -> URL?
    /// 캐시된 URL 값만 확인
//    func getCachedFattenImageURL(forId id: String) throws -> URL?
    /// 캐시된 URL 값만 확인
    // func getCachedEditImageURL(forId id: String) throws -> URL?
    
    
    func clearCached(forHei hei: HEImage, includeOrigin: Bool) async
    func clearAllCachedFiles() async
}

public extension HEImageCache {
    func clearCached(forHei hei: HEImage) async {
        await clearCached(forHei: hei, includeOrigin: false)
    }
}

@MainActor
public protocol HEImageDataStore {
    func addHEImage(_ hei: HEImage, excepting: ((HEImage) -> Bool)?)
    func addHEImages(_ heis: [HEImage], excepting: ((HEImage) -> Bool)?)
    
    func removeHEImage(_ id: String)
    func removeHEImage(_ he: HEImage)
    func clearAll()
    
    func all() -> [HEImage]
    func numberOfImages() -> Int
    func getHEImage(at index: Int) -> HEImage?
    
    func getHEImage(forId id: String) -> HEImage?
    func getHEImage(forAssetIdentifier identifier: String) -> HEImage?
    
    @discardableResult
    func replaceHEImage(at index: Int, with item: HEImage) -> Bool
    
    @discardableResult
    func replaceHEImage(_ exist: HEImage, with item: HEImage) -> Bool
    
    func sorts(byIds ids: [String])
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


public protocol HEEditImageStore: HEImageDataStore, HEImageCache {}

/// 간단히 구현된 편집용 이미지 스토어
public class HESimpleEditImageStore: HEEditImageStore {

    public init(){}
    
    let memCache = NSCache<NSString, UIImage>()
    let thumbCache = NSCache<NSString, UIImage>()
    var images: [HEImage] = []

    public func removeHEImage(_ id: String) {
        images.removeAll(where: { $0.id == id })
    }
    
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

// MARK: HEImageCache
extension HESimpleEditImageStore {
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
    
    public func fattenImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let fattenImageURL = hei.fattenImageURL {
                return try await getImage(forURL: fattenImageURL).value
            }
            else {
                return try await originImage(forHei: hei).value
            }
        }
    }
    
    public func editImage(forHei hei: HEImage) -> Task<UIImage, Error> {
        Task {
            if let editImageURL = hei.editImageURL {
                return try await getImage(forURL: editImageURL).value
            }
            else {
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
    
//    @available(*, deprecated, message: "원본 경로를 id 로 측정하는 데 문제가 있음")
//    public func getCachedOriginImageURL(forId id: String) throws -> URL? {
//        let fileName = id.heImageCacheOriginFileName
//        let fileURL: URL = try fileURL(fileName: fileName)
//        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
//            return fileURL
//        }
//        return nil
//    }
//    
//    public func getCachedFattenImageURL(forId id: String) throws -> URL? {
//        let fileName = id.heImageCacheFattenFileName
//        let fileURL: URL = try fileURL(fileName: fileName)
//        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
//            return fileURL
//        }
//        return nil
//    }
    
//    public func getCachedEditImageURL(forId id: String) throws -> URL? {
//        let fileName = id.heImageCacheEditFileName
//        let fileURL: URL = try fileURL(fileName: fileName)
//        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
//            return fileURL
//        }
//        return nil
//    }
    
    // MARK: Caching -
    
    @available(*, deprecated)
    public func cacheOriginImage(uiImage: UIImage, forId id: String) -> Task<URL, Error> {
        return Task.detached { [weak self] in
            guard let self else {
                throw HEError.generateFileData
            }
            return try await self.cacheOriginImageSync(uiImage: uiImage, forId: id)
        }
    }
    
    public func cacheOriginImage(uiImage: UIImage, forId id: String, isGif: Bool) -> Task<URL, Error> {
        return Task.detached { [weak self] in
            guard let self else {
                throw HEError.generateFileData
            }
            return try await self.cacheOriginImageSync(uiImage: uiImage, forId: id, isGif: isGif)
        }
    }
    
    public func cacheOriginImageSync(uiImage: UIImage, forId id: String, isGif: Bool) throws -> URL {
        if isGif, let data = uiImage.he.gifData() {
            return try cacheOriginImageSync(imageData: data, forId: id, isGif: true)
        } else if let data = uiImage.he.fixOrientation().jpegData(compressionQuality: 0.8) {
            return try cacheOriginImageSync(imageData: data, forId: id, isGif: false)
        } else {
            throw HEError.generateFileData
        }
    }
    
    public func cacheOriginImage(imageData: Data, forId id: String, isGif: Bool) -> Task<URL, any Error> {
        return Task.detached { [weak self] in
            guard let self else {
                throw HEError.generateFileData
            }
            return try await self.cacheOriginImageSync(imageData: imageData, forId: id, isGif: isGif)
        }
    }
    
    @available(*, deprecated)
    public func cacheOriginImageSync(uiImage: UIImage, forId id: String) throws -> URL {
        if uiImage.he.isGIF(), let data = uiImage.he.gifData() {
            return try cacheOriginImageSync(imageData: data, forId: id, isGif: true)
        } else if let data = uiImage.jpegData(compressionQuality: 0.8) {
            return try cacheOriginImageSync(imageData: data, forId: id, isGif: false)
        } else {
            throw HEError.generateFileData
        }
    }
    
    public func cacheOriginImageSync(imageData: Data, forId id: String, isGif: Bool) throws -> URL {
        let fileName = id.toHEImageCacheIdentifier() + (isGif ? ".gif" : ".jpg")
        let fileURL: URL = try fileURL(fileName: fileName)
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
    
    public func cacheFattenImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, any Error> {
        return Task.detached { [weak self] in
            guard let self else {
                throw HEError.generateFileData
            }
            return try await self.cacheFattenImageSync(uiImage: uiImage, forHei: hei)
        }
    }
    
    public func cacheFattenImageSync(uiImage: UIImage, forHei hei: HEImage) throws -> URL {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            throw HEError.generateFileData
        }
        return try cacheFattenImageSync(imageData: data, forHei: hei)
    }
    
    public func cacheFattenImageSync(imageData: Data, forHei hei: HEImage) throws -> URL {
        let fileName = hei.id.heImageCacheFattenFileName()
        let fileURL: URL = try fileURL(fileName: fileName)
        FileManager.default.createFile(atPath: fileURL.path, contents: imageData)
        hei.setFattenImageURL(fileURL)
        
        lg.trace(imageData.he.fileSizeInKB)
        
        Task.detached { [weak self] in
            if let uiImage = UIImage(data: imageData) {
                await self?.memCacheImage(uiImage, forUrl: fileURL)
            }
        }
        
        return fileURL
    }
    
    public func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error> {
        let fileName = hei.id.heImageCacheEditFileName()
        return Task.detached { [weak self] in
            guard let self, let data = uiImage.jpegData(compressionQuality: 0.8) else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try await fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await memCacheImage(uiImage, forUrl: fileURL)
            hei.setEditImageURL(fileURL)
            
            lg.trace(data.he.fileSizeInKB)
            
            return fileURL
        }
    }
    
    public func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) -> Task<URL, Error> {
        let fileName = hei.id.heImageCacheThumbFileName()
        return Task.detached { [weak self] in
            let thumbnail = uiImage.he.thumbnail()
            guard let self, let data = thumbnail.jpegData(compressionQuality: 0.6) else {
                throw HEError.generateFileData
            }
            let fileURL: URL = try await fileURL(fileName: fileName)
            FileManager.default.createFile(atPath: fileURL.path, contents: data)
            
            await memCacheImage(uiImage, forUrl: fileURL)
            hei.setThumbnailURL(fileURL)
            
            lg.trace(data.he.fileSizeInKB)
            
            return fileURL
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
        
        hei.setFattenImageURL(nil)
        hei.setEditImageURL(nil)
        hei.setThumbnailURL(nil)
    }
    
    public func clearAllCachedFiles() async {
        do {
            try FileManager.default.removeItem(at: directoryURL())
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
    
    func memCacheImage(_ image: UIImage, forUrl url: URL) {
        memCache.setObject(image, forKey: NSString(string: url.absoluteString))
    }
    
    func getMemCachedImage(forUrl url: URL) -> UIImage? {
        return memCache.object(forKey: NSString(string: url.absoluteString))
    }
    
    func clearMemCachedImage(forUrl url: URL) {
        memCache.removeObject(forKey: NSString(string: url.absoluteString))
    }
    
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
            if let cached = await self?.getMemCachedImage(forUrl: url) {
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
    
    func getImageSync(forURL url: URL) throws -> UIImage? {
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
