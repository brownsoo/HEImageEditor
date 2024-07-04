//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit


public protocol HEImagePickerDelegate: HEPickerLibraryViewDelegate {
    func imagePickerDidFinishPicking(_ picker: HEImagePicker, items: [HEMediaItem], cancelled: Bool) -> Void
}

open class HEImagePicker: UINavigationController {
    
    public weak var imagePickerDelegate: HEImagePickerDelegate?
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        PickerConfig.preferredStatusBarStyle
    }
    
    private lazy var mainVc: HEPickerLibraryViewController = HEPickerLibraryViewController()
    
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
    
    open override func loadView() {
        super.loadView()
        setViewControllers([mainVc], animated: false)
    }
    
}
