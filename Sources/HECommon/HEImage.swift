//
//  HEImage.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import Foundation
import UIKit

open class HEImage: CustomDebugStringConvertible {
    
    public let id: String
    public let originURL: URL?
    public let originImage: UIImage?
    
    public var updatedTime: TimeInterval
    public internal(set) var editImageURL: URL?
    public internal(set) var fattenImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    
    public init(id: String = UUID().uuidString, origin: URL) {
        self.id = id
        self.originURL = origin
        self.originImage = nil
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public init(id: String = UUID().uuidString, image: UIImage) {
        self.id = id
        self.originURL = nil
        self.originImage = image
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    init(id: String,
         origin: URL?,
         originImage: UIImage?) {
        self.id = id
        self.originURL = origin
        self.originImage = originImage
        self.updatedTime = Date().timeIntervalSince1970
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
    
    public func clone(withNewId newId: String) -> HEImage {
        let hei = HEImage(id: newId,
                          origin: self.originURL,
                          originImage: self.originImage
        )
        hei.editImageURL = self.editImageURL
        hei.fattenImageURL = self.fattenImageURL
        hei.thumbnailURL = self.thumbnailURL
        hei.updatedTime = self.updatedTime
        return hei
    }
    
    open var debugDescription: String {
        """
HEImage::
- id\(id)
- originURL: \(originURL?.absoluteString ?? "nil")
- editImageURL: \(editImageURL?.absoluteString ?? "nil")
- fattenImageURL: \(fattenImageURL?.absoluteString ?? "nil")
- thumbnailURL: \(thumbnailURL?.absoluteString ?? "nil")
- updatedTime: \(updatedTime)
"""
    }
}
