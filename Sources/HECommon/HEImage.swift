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
    
    public func setEditImageURL(_ url: URL?) {
        self.editImageURL = url
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public func setThumbnailURL(_ url: URL?) {
        self.thumbnailURL = url
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    open var debugDescription: String {
        """
HEImage::
- id\(id)
- originURL: \(originURL?.absoluteString ?? "nil")
- editImageURL: \(editImageURL?.absoluteString ?? "nil")
- thumbnailURL: \(thumbnailURL?.absoluteString ?? "nil")
"""
    }
}
