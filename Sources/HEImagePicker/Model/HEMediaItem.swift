//
//  HEMediaItem.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/2/24.
//
import UIKit
import Foundation
import AVFoundation
import Photos
import HECommon

public typealias HEMediaPhotoExtraTask = () async -> (thumbnail: UIImage?, exifMeta:  [String: Any]?)

/// HEPicker 의 사진
public class HEMediaPhoto {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public let url: URL
    public let fromCamera: Bool
    public var asset: PHAsset?
    public var extraTask: HEMediaPhotoExtraTask?
    
    public init(identifier: String?,
                url: URL,
                thumbnail: UIImage?,
                exifMeta: [String: Any]? = nil,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.url = url
        self.extraTask = { (thumbnail, exifMeta) }
        self.fromCamera = fromCamera
        self.asset = asset
    }
    
    public init(identifier: String?,
                url: URL,
                extraTask: HEMediaPhotoExtraTask? = nil,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.url = url
        self.extraTask = extraTask
        self.fromCamera = fromCamera
        self.asset = asset
    }
}

public extension HEImage {
    func toMediaPhoto(imageCache: HEImageCache) throws -> HEMediaPhoto {
        let hei = self
        let originURL: URL
        let extraTask: HEMediaPhotoExtraTask
        // 편집 이미지 우선
        
        if let url = self.editImageURL {
            originURL = url
            extraTask = {
                let image = try? await imageCache.editImage(forHei: hei).value
                let thumbnail = image?.he.thumbnail()
                let meta = image?.pngData()?.he.metadataForImageData()
                return (thumbnail, meta)
            }
            
        } else if let url = self.originURL {
            originURL = url
            extraTask = {
                let image = try? await imageCache.originImage(forHei: hei).value
                let thumbnail = image?.he.thumbnail()
                let meta = image?.pngData()?.he.metadataForImageData()
                return (thumbnail, meta)
            }
            
        } else if let originImage = hei.originImage {
            originURL = try imageCache.cacheOriginImageSync(uiImage: originImage, forId: hei.id)
            extraTask = {
                let thumbnail = originImage.he.thumbnail()
                let meta = originImage.pngData()?.he.metadataForImageData()
                return (thumbnail, meta)
            }
        } else {
            
            throw HEError.heImageHasNoData
        }
        
        return HEMediaPhoto(identifier: hei.id,
                            url: originURL,
                            extraTask: extraTask)
    }
}



/// HEPicker 의 비디오 
public class HEMediaVideo {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public var url: URL
    public let fromCamera: Bool
    public var asset: PHAsset?
    public var thumbnailTask: (() async -> UIImage?)?

    public init(identifier: String?,
                thumbnail: UIImage,
                videoURL: URL,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.thumbnailTask = { thumbnail }
        self.url = videoURL
        self.fromCamera = fromCamera
        self.asset = asset
    }
    
    public init(identifier: String?,
                videoURL: URL,
                thumbnailTask: (() async -> UIImage?)?,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.thumbnailTask = thumbnailTask
        self.url = videoURL
        self.fromCamera = fromCamera
        self.asset = asset
    }
}

/// HEPicker's representive media item includes photo or video
public enum HEMediaItem {
    case photo(p: HEMediaPhoto)
    case video(v: HEMediaVideo)
}

public extension HEMediaItem {
    var identifier: String {
        switch self {
        case .photo(let p): return p.identifier
        case .video(let v): return v.identifier
        }
    }
    
    var phAsset: PHAsset? {
        switch self {
        case .photo(let p): return p.asset
        case .video(let v): return v.asset
        }
    }
}


// MARK: - Compression

public extension HEMediaVideo {
    /// Fetches a video data with selected compression in HEImagePickerConfiguration
    func fetchData(completion: (_ videoData: Data) -> Void) {
        // TODO: place here a compression code. Use HEConfig.videoCompression and HEConfig.videoExtension
        completion(Data())
    }
}

// MARK: - Easy access

public extension Array where Element == HEMediaItem {
    var singlePhoto: HEMediaPhoto? {
        if let f = first, case let .photo(p) = f {
            return p
        }
        return nil
    }
    
    var singleVideo: HEMediaVideo? {
        if let f = first, case let .video(v) = f {
            return v
        }
        return nil
    }
    
    var photoItems: [HEMediaPhoto] {
        self.compactMap { it in
            if case let .photo(p) = it {
                return p
            }
            return nil
        }
    }
    
    var videoItems: [HEMediaVideo] {
        self.compactMap { it in
            if case let .video(v) = it {
                return v
            }
            return nil
        }
    }
}
