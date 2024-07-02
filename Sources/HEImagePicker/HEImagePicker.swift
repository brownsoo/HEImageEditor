//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit


public protocol HEImagePickerDelegate: AnyObject {
    func imagePickerHasNoItemsInLibrary(_ picker: HEImagePicker)
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
    func imagePickerDidFinishPicking(_ picker: HEImagePicker, items: [HEMediaItem], cancelled: Bool) -> Void
}

open class HEImagePicker: UINavigationController {
    
    public weak var imagePickerDelegate: HEImagePickerDelegate?
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        PickerConfig.preferredStatusBarStyle
    }
    
    public convenience init() {
        self.init(configuration: HEImagePickerConfiguration.shared)
    }
    
    
    public required init(configuration: HEImagePickerConfiguration) {
        HEImagePickerConfiguration.shared = configuration
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
