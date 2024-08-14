//
//  HEImage.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import Foundation
import UIKit
import Photos

open class HEImage: CustomDebugStringConvertible {
    
    public let id: String
    public let originURL: URL?
    public let originImage: UIImage?
    
    public var updatedTime: TimeInterval
    public internal(set) var editImageURL: URL?
    public internal(set) var fattenImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    public internal(set) var phAsset: PHAsset?
    public internal(set) var phAssetIdentifier: String?
    
    public init(id: String = UUID().uuidString, origin: URL, phAsset: PHAsset? = nil) {
        self.id = id
        self.originURL = origin
        self.originImage = nil
        self.updatedTime = Date().timeIntervalSince1970
        self.phAsset = phAsset
        self.phAssetIdentifier = phAsset?.localIdentifier
    }
    
    public init(id: String = UUID().uuidString, image: UIImage, phAsset: PHAsset? = nil) {
        self.id = id
        self.originURL = nil
        self.originImage = image
        self.updatedTime = Date().timeIntervalSince1970
        self.phAsset = phAsset
        self.phAssetIdentifier = phAsset?.localIdentifier
    }
    
    init(id: String,
         origin: URL?,
         originImage: UIImage?,
         phAsset: PHAsset?) {
        self.id = id
        self.originURL = origin
        self.originImage = originImage
        self.updatedTime = Date().timeIntervalSince1970
        self.phAsset = phAsset
        self.phAssetIdentifier = phAsset?.localIdentifier
    }
    
    public func setEditImageURL(_ url: URL?) {
        self.editImageURL = url
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public func setFattenImageURL(_ url: URL?) {
        self.fattenImageURL = url
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public func setThumbnailURL(_ url: URL?) {
        self.thumbnailURL = url
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public func setPHAsset(_ asset: PHAsset?) {
        self.phAsset = asset
    }
    
    open func clone(withNewId newId: String) -> HEImage {
        let hei = HEImage(id: newId,
                          origin: self.originURL,
                          originImage: self.originImage, 
                          phAsset: self.phAsset
        )
        hei.editImageURL = self.editImageURL
        hei.fattenImageURL = self.fattenImageURL
        hei.thumbnailURL = self.thumbnailURL
        hei.updatedTime = self.updatedTime
        hei.phAssetIdentifier = self.phAssetIdentifier
        return hei
    }
    
    open var debugDescription: String {
        """
HEImage::
    - id: \(id)
    - originURL: \(originURL?.absoluteString ?? "nil")
    - editImageURL: \(editImageURL?.absoluteString ?? "nil")
    - fattenImageURL: \(fattenImageURL?.absoluteString ?? "nil")
    - thumbnailURL: \(thumbnailURL?.absoluteString ?? "nil")
    - updatedTime: \(updatedTime)
    - phAsset: \(self.phAsset?.localIdentifier ?? "nil")
    - phAssetIdentifier: \(self.phAssetIdentifier ?? "nil")
"""
    }
}
