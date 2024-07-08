//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit


public protocol HEImagePickerDelegate: AnyObject {
    func imagePickerHaveNoItems(_ picker: HEImagePicker)
    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem])
    func imagePickerDidCancel(_ picker: HEImagePicker)
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelectionAt indexPath: IndexPath, numSelections: Int) -> Bool
    func imagePicker(_ picker: HEImagePicker, captionAt indexPath: IndexPath) -> String?
    func imagePicker(_ picker: HEImagePicker, replacingItemAt indexPath: IndexPath) -> HEMediaItem?
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem)
}

public extension HEImagePickerDelegate {
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelectionAt indexPath: IndexPath, numSelections: Int) -> Bool {
        true
    }
    func imagePickerHaveNoItems(_ picker: HEImagePicker) {}
}

open class HEImagePicker: UINavigationController {
    
    public weak var pickerDelegate: HEImagePickerDelegate?
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        PickerConfig.preferredStatusBarStyle
    }
    
    private lazy var mainVc: HELibraryViewController = HELibraryViewController()
    
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
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [mainVc]
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .ypLabel
        view.backgroundColor = .ypSystemBackground
        mainVc.delegate = self
    }
    
}

extension HEImagePicker: HELibraryViewDelegate {
    public func libraryViewHaveNoItems(_ libraryView: HELibraryViewController) {
        pickerDelegate?.imagePickerHaveNoItems(self)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didToggleMultipleSelectionEnabled enabled: Bool) {
        trace(enabled)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, shouldAddToSelectionAt indexPath: IndexPath, numSelections: Int) -> Bool {
        pickerDelegate?.imagePicker(self, shouldAddToSelectionAt: indexPath, numSelections: numSelections) ?? true
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, captionAt indexPath: IndexPath) -> String? {
        pickerDelegate?.imagePicker(self, captionAt: indexPath)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, replacingItemAt indexPath: IndexPath) -> HEMediaItem? {
        pickerDelegate?.imagePicker(self, replacingItemAt: indexPath)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didSelectItems items: [HEMediaItem]) {
        pickerDelegate?.imagePicker(self, didSelectItems: items)
    }
    
    public func libraryViewDidCancel(_ libraryView: HELibraryViewController) {
        pickerDelegate?.imagePickerDidCancel(self)
    }
    
}
