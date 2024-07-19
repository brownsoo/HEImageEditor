//
//  HEEditImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import HECommon

public class HEEditImage: HEImage {
    
    public internal(set) var editState: HEEditState?
    
    public init(id: String = UUID().uuidString, origin: URL, editState: HEEditState?) {
        super.init(id: id, origin: origin)
        self.editState = editState
    }
    
    public init(id: String = UUID().uuidString, image: UIImage, editState: HEEditState?) {
        super.init(id: id, image: image)
        self.editState = editState
    }
    
    public func setEditState(_ model: HEEditState?) {
        self.editState = model
    }
    
    public override var debugDescription: String {
        """
HEEditImage::
- id\(id)
- originURL: \(originURL?.absoluteString ?? "nil")
- editImageURL: \(editImageURL?.absoluteString ?? "nil")
- thumbnailURL: \(thumbnailURL?.absoluteString ?? "nil")
- editState: \(editState != nil)
"""
    }
}

public extension HEEditImage {
    static func fromHEImage(_ hei: HEImage) -> HEEditImage? {
        if let e = hei as? HEEditImage {
            return e
        }
        if let originURL = hei.originURL {
            return HEEditImage(id: hei.id, origin: originURL, editState: nil)
        }
        if let originImage = hei.originImage {
            return HEEditImage(id: hei.id, image: originImage, editState: nil)
        }
        return nil
    }
}

public extension HEImage {
    func toEditImage() -> HEEditImage? {
        return HEEditImage.fromHEImage(self)
    }
}
