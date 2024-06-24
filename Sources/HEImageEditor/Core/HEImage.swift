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
    
    public internal(set) var editModel: HEEditImageModel?
    public internal(set) var editImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    
    public init(id: String = UUID().uuidString, origin: URL, editModel: HEEditImageModel?) {
        self.id = id
        self.originURL = origin
        self.originImage = nil
        self.editModel = editModel
    }
    
    public init(id: String = UUID().uuidString, image: UIImage, editModel: HEEditImageModel?) {
        self.id = id
        self.originURL = nil
        self.originImage = image
        self.editModel = editModel
    }
    
//    public init(phpickResult: PHPickerResult) {
//        self.id = phpickResult.assetIdentifier!
//        self.originURL = phpickResult.itemProvider.
//    }
    
    public func setEditModel(_ model: HEEditImageModel?) {
        self.editModel = model
    }
    
    public func setEditImageURL(_ url: URL?) {
        self.editImageURL = url
    }
    
    public func setThumbnailURL(_ url: URL?) {
        self.thumbnailURL = url
    }
}
