//
//  HEImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit

public actor HEImage {
    
    public let id: String
    public let originURL: URL?
    public let originImage: UIImage?
    
    public var editModel: HEEditImageModel?
    public internal(set) var editImageURL: URL?
    public internal(set) var thumbnailURL: URL?
    
    public init(origin: URL, editModel: HEEditImageModel?) {
        self.id = origin.absoluteString
        self.originURL = origin
        self.originImage = nil
        self.editModel = editModel
    }
    
    public init(image: UIImage, editModel: HEEditImageModel?) {
        self.id = UUID().uuidString
        self.originURL = nil
        self.originImage = image
        self.editModel = editModel
    }
    
    func setEditImageURL(_ url: URL) async {
        self.editImageURL = url
    }
    
    func setThumbnailURL(_ url: URL) async {
        self.thumbnailURL = url
    }
}
