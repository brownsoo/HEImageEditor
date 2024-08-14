//
//  HEEditImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import HECommon
import Photos

public class HEEditImage: HEImage {
    
    public internal(set) var editState: HEEditState?
    
    public init(id: String = UUID().uuidString, origin: URL, editState: HEEditState?, phAsset: PHAsset? = nil) {
        super.init(id: id, origin: origin, phAsset: phAsset)
        self.editState = editState
    }
    
    public init(id: String = UUID().uuidString, image: UIImage, editState: HEEditState?, phAsset: PHAsset? = nil) {
        super.init(id: id, image: image, phAsset: phAsset)
        self.editState = editState
    }
    
    public init?(hei: HEImage) {
        if let originURL = hei.originURL {
            super.init(id: hei.id, origin: originURL, phAsset: hei.phAsset)
        } else if let originImage = hei.originImage {
            super.init(id: hei.id, image: originImage, phAsset: hei.phAsset)
        } else {
            return nil
        }
        
        setEditImageURL(hei.editImageURL)
        setFattenImageURL(hei.fattenImageURL)
        setThumbnailURL(hei.thumbnailURL)
        setEditState((hei as? HEEditImage)?.editState)
        
        self.updatedTime = hei.updatedTime
    }
    
    public func setEditState(_ model: HEEditState?) {
        self.editState = model
        self.updatedTime = Date().timeIntervalSince1970
    }
    
    public override func clone(withNewId newId: String) -> HEImage {
        let copy = super.clone(withNewId: newId)
        guard let hei = HEEditImage.fromHEImage(copy) else {
            return copy
        }
        hei.editState = self.editState?.clone()
        return hei
    }
    
    public override var debugDescription: String {
        """
HEEditImage::
    - id: \(id)
    - originURL: \(originURL?.absoluteString ?? "nil")
    - editImageURL: \(editImageURL?.absoluteString ?? "nil")
    - fattenImageURL: \(fattenImageURL?.absoluteString ?? "nil")
    - thumbnailURL: \(thumbnailURL?.absoluteString ?? "nil")
    - updatedTime: \(updatedTime)
    - phAsset: \(self.phAsset?.localIdentifier ?? "nil")
    - editState.fattened: \(editState?.fattened ?? false)
    - editState.clipStatus.angle: \(editState?.clipStatus?.angle ?? 0)
"""
    }
}

public extension HEEditImage {
    static func fromHEImage(_ hei: HEImage) -> HEEditImage? {
        if let e = hei as? HEEditImage {
            return e
        }
        return HEEditImage(hei: hei)
    }
}

public extension HEImage {
    func toEditImage() -> HEEditImage? {
        return HEEditImage.fromHEImage(self)
    }
}
