//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit


public protocol HEImagePickerViewDelegate: AnyObject {
    func imagePickerHasNoItemsInLibrary(_ picker: HEImagePickerView)
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
    func imagePickerDidFinishPicking(_ picker: HEImagePickerView, items: [HEMediaItem], cancelled: Bool) -> Void
}

open class HEImagePickerView: UINavigationController {
    
    public weak var imagePickerDelegate: HEImagePickerViewDelegate?
    
    public convenience init() {
        
    }
    
    
    public required init(configuration: HEImagePickerConfiguration) {
        
    }
}
