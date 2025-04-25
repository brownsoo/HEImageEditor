//
//  HEImageCache.swift
//  HEImageEditor
//
//  Created by hyonsoo on 10/19/24.
//
import Foundation
import UIKit

public protocol HEImageCache {
    
    /// 원본 이미지 캐시
    func cacheOriginImage(uiImage: UIImage, forId id: String, isGif: Bool) async throws -> URL
    /// 원본 이미지 캐시
    func cacheOriginImage(imageData: Data, forId id: String, isGif: Bool) async throws -> URL
    
    /// 중간 정리된 이미지 캐시
    func cacheFattenImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL
    /// 편집 이미지 캐시
    func cacheEditImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL
    /// 썸네일 이미지 캐시
    func cacheThumbnailImage(uiImage: UIImage, forHei hei: HEImage) async throws -> URL
    
    
    /// 원본 이미지
    func originImage(forHei hei: HEImage) async throws -> UIImage
    /// 중간 이미지 or 원본 이미지
    func fattenImage(forHei hei: HEImage) async throws -> UIImage
    /// 편집 이미지 or 원본 이미지
    func editImage(forHei hei: HEImage) async throws -> UIImage
    /// 썸네일 이미지
    func thumbnailImage(forHei hei: HEImage) async throws -> UIImage
    
    func clearCached(forHei hei: HEImage, includeOrigin: Bool) async
    
    func clearAllCachedFiles() async
}

public extension HEImageCache {
    func clearCached(forHei hei: HEImage) async {
        await clearCached(forHei: hei, includeOrigin: false)
    }
}
