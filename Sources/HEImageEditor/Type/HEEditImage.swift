//
//  HEEditImage.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import HECommon

@MainActor
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
}
