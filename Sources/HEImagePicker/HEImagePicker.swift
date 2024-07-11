//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit
import HECommon

public protocol HEImagePickerDelegate: AnyObject {
    func imagePickerHaveNoItems(_ picker: HEImagePicker)
    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem])
    func imagePickerDidCancel(_ picker: HEImagePicker)
    /// 선택할 수 있는 지
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelection identifier: String, numSelections: Int) -> Bool
    func imagePicker(_ picker: HEImagePicker, captionWithIdentifer identifier: String) -> String?
    
    func imagePicker(_ picker: HEImagePicker, replacingItemWithIdentifer identifier: String) -> HEMediaItem?
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem, inItems items: [HEMediaItem])
    /// 카메라를 통해 캡쳐되어 선택됨.
    ///
    /// - PickerConfig.shouldSaveNewPicturesToAlbum 가 false 일 때, 호출된다.
    func imagePicker(_ picker: HEImagePicker, didCaptureItem item: HEMediaItem)
}

public extension HEImagePickerDelegate {
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelection identifier: String, numSelections: Int) -> Bool {
        true
    }
    func imagePickerHaveNoItems(_ picker: HEImagePicker) {}
    
    func imagePicker(_ picker: HEImagePicker, replacingItemWithIdentifer identifier: String) -> HEMediaItem? { nil }
}

open class HEImagePicker: UINavigationController, HEPickerNavigationController {
    
    public weak var pickerDelegate: HEImagePickerDelegate?
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        PickerConfig.preferredStatusBarStyle
    }
    
    public var editImageStore: HEEditImageStore? = nil {
        willSet {
            mainVc.editImageStore = newValue ?? HESimpleEditImageStore()
        }
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
    
    public func reload() {
        mainVc.v.previewBox.reload()
        mainVc.v.albumCollectionView.reloadData()
    }
}

extension HEImagePicker: HELibraryViewDelegate {
    public func libraryViewHaveNoItems(_ libraryView: HELibraryViewController) {
        pickerDelegate?.imagePickerHaveNoItems(self)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didToggleMultipleSelectionEnabled enabled: Bool) {
        trace(enabled)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, shouldAddToSelection identifier: String, numSelections: Int) -> Bool {
        pickerDelegate?.imagePicker(self, shouldAddToSelection: identifier, numSelections: numSelections) ?? true
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, captionWithIdentifer identifier: String) -> String? {
        pickerDelegate?.imagePicker(self, captionWithIdentifer: identifier)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, replacingItemWithIdentifer identifier: String) -> HEMediaItem? {
        self.pickerDelegate?.imagePicker(self, replacingItemWithIdentifer: identifier)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didSelectItems items: [HEMediaItem], wantsEditSelection: HELibrarySelection?) {
        if let wantsEditSelection {
            guard let item = items.first(where: { $0.identifier == wantsEditSelection.assetIdentifier }) ?? items.first else {
                showAlert(PickerConfig.wordings.noSelectionToEdit)
                return
            }
            pickerDelegate?.imagePicker(self, didSelectToEditItem: item, inItems: items)
        } else {
            pickerDelegate?.imagePicker(self, didSelectItems: items)
        }
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didCaptureItem item: HEMediaItem) {
        pickerDelegate?.imagePicker(self, didCaptureItem: item)
    }
    
    public func libraryViewDidCancel(_ libraryView: HELibraryViewController) {
        pickerDelegate?.imagePickerDidCancel(self)
    }
    
}
