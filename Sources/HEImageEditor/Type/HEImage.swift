//
//  HEImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import PhotosUI

@MainActor
public class HEImage {
    
    public let id: String
    public let originURL: URL?
    public let originImage: UIImage?
    
    public internal(set) var editState: HEEditState?
    public internal(set) var editImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    
    public init(id: String = UUID().uuidString, origin: URL, editState: HEEditState?) {
        self.id = id
        self.originURL = origin
        self.originImage = nil
        self.editState = editState
    }
    
    public init(id: String = UUID().uuidString, image: UIImage, editState: HEEditState?) {
        self.id = id
        self.originURL = nil
        self.originImage = image
        self.editState = editState
    }
    
    public func setEditState(_ model: HEEditState?) {
        self.editState = model
    }
    
    public func setEditImageURL(_ url: URL?) {
        self.editImageURL = url
    }
    
    public func setThumbnailURL(_ url: URL?) {
        self.thumbnailURL = url
    }
}
