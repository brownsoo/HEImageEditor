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

/// HEPicker 의 사진
public class HEMediaPhoto {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public let url: URL
    public var thumbnail: UIImage?
    public let fromCamera: Bool
    public let exifMeta: [String: Any]?
    public var asset: PHAsset?
    
    public init(identifier: String?,
                url: URL,
                thumbnail: UIImage?,
                exifMeta: [String: Any]? = nil,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.url = url
        self.thumbnail = thumbnail
//        self.modifiedImage = nil
        self.fromCamera = fromCamera
        self.exifMeta = exifMeta
        self.asset = asset
    }
}

public extension HEImage {
    func toMediaPhoto(imageCache: HEImageCache) throws -> HEMediaPhoto {
        let hei = self
        let originURL: URL
        let thumbnail: UIImage?
        let meta: [String : Any]?
        // 편집 이미지 우선
        
        if let url = self.editImageURL {
            originURL = url
            let image = try imageCache.editImageSync(forHei: hei)
            thumbnail = image?.he.thumbnail()
            meta = image?.pngData()?.he.metadataForImageData()
            
        } else if let url = self.originURL {
            originURL = url
            let image = try imageCache.originImageSync(forHei: hei)
            thumbnail = image?.he.thumbnail()
            meta = image?.pngData()?.he.metadataForImageData()
            
        } else if let originImage = hei.originImage {
            originURL = try imageCache.cacheOriginImageSync(uiImage: originImage, forId: hei.id)
            thumbnail = originImage.he.thumbnail()
            meta = originImage.pngData()?.he.metadataForImageData()
            
        } else {
            
            throw HEError.heImageHasNoData
        }
        
        return HEMediaPhoto(identifier: hei.id,
                            url: originURL,
                            thumbnail: thumbnail,
                            exifMeta: meta)
    }
}



/// HEPicker 의 비디오 
public class HEMediaVideo {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public var url: URL
    public var thumbnail: UIImage
    public let fromCamera: Bool
    public var asset: PHAsset?

    public init(identifier: String?,
                thumbnail: UIImage,
                videoURL: URL,
                fromCamera: Bool = false,
                asset: PHAsset? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.thumbnail = thumbnail
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
}
