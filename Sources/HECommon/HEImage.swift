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
    
    public internal(set) var editImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    
    public init(id: String = UUID().uuidString, origin: URL) {
        self.id = id
        self.originURL = origin
        self.originImage = nil
    }
    
    public init(id: String = UUID().uuidString, image: UIImage) {
        self.id = id
        self.originURL = nil
        self.originImage = image
    }
    
    public func setEditImageURL(_ url: URL?) {
        self.editImageURL = url
    }
    
    public func setThumbnailURL(_ url: URL?) {
        self.thumbnailURL = url
    }
    
    public var debugDescription: String {
        """
HEImage::
- id\(id)
- originURL: \(originURL?.absoluteString ?? "nil")
- editImageURL: \(editImageURL?.absoluteString ?? "nil")
"""
    }
}
