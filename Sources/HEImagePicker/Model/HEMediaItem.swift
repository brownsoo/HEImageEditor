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

public class HEMediaPhoto {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public var image: UIImage { return modifiedImage ?? originalImage }
    public let originalImage: UIImage
    public var modifiedImage: UIImage?
    public let fromCamera: Bool
    public let exifMeta: [String: Any]?
    public var asset: PHAsset?
    public var url: URL?
    
    public init(identifier: String? = nil,
                image: UIImage,
                exifMeta: [String: Any]? = nil,
                fromCamera: Bool = false,
                asset: PHAsset? = nil,
                url: URL? = nil) {
        self.identifier = identifier ?? asset?.localIdentifier ?? UUID().uuidString
        self.originalImage = image
        self.modifiedImage = nil
        self.fromCamera = fromCamera
        self.exifMeta = exifMeta
        self.asset = asset
        self.url = url
    }
}

public class HEMediaVideo {
    /// 지정된 아이디 or PHAsset의 identifier, or uuid
    public var identifier: String
    public var thumbnail: UIImage
    public var url: URL
    public let fromCamera: Bool
    public var asset: PHAsset?

    public init(identifier: String? = nil,
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

/// HEPicker's representive media item
public enum HEMediaItem {
    case photo(p: HEMediaPhoto)
    case video(v: HEMediaVideo)
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
