//
//  HEImagePicker.swift
//  HEImageEditor
//
//  Created by hyonsoo on 7/1/24.
//  YPImagePicker 소스를 포팅하며, 개선했습니다.

import Foundation
import UIKit
import HECommon
import Photos

@MainActor
public protocol HEImagePickerDelegate: AnyObject {
    func imagePickerHaveNoItems(_ picker: HEImagePicker)
    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem])
    func imagePickerDidCancel(_ picker: HEImagePicker)
    /// 선택할 수 있는 지
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelection identifier: String, numSelections: Int) -> Bool
    func imagePicker(_ picker: HEImagePicker, captionWithIdentifer identifier: String) -> String?
    
    func imagePicker(_ picker: HEImagePicker, replacingItemWithIdentifer identifier: String) -> HEMediaItem?
    /// 편집하기 버튼을 선택함
    /// 
    /// - Parameters:
    ///   - picker: HEImagePicker
    ///   - item: selected item
    ///   - items: all selected items in ordered
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem, inItems items: [HEMediaItem])
    /// 카메라를 통해 캡쳐되어 선택됨.
    ///
    /// - PickerConfig.shouldSaveNewPicturesToAlbum 가 false 일 때, 호출된다.
    func imagePicker(_ picker: HEImagePicker, didCaptureItem item: HEMediaItem)
    /// 해당 타임을 선택할 수 없음
    func imagePicker(_ picker: HEImagePicker, cannotSelectItemType type: PHAssetMediaType?)
    /// 선택 가능한 수를 초과함
    func imagePicker(_ picker: HEImagePicker, limitExceededOnSelectItemType type: PHAssetMediaType)
}

public extension HEImagePickerDelegate {
    func imagePicker(_ picker: HEImagePicker, captionWithIdentifer identifier: String) -> String? {
        if let hei = picker.editImageStore.getHEImage(forId: identifier),
           hei.editImageURL != nil {
            return PickerConfig.wordings.edited
        }
        if let hei = picker.editImageStore.getHEImage(forAssetIdentifier: identifier),
           hei.editImageURL != nil {
            return PickerConfig.wordings.edited
        }
        return nil
    }
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelection identifier: String, numSelections: Int) -> Bool {
        return true
    }
    func imagePickerHaveNoItems(_ picker: HEImagePicker) {}
    
    @MainActor
    func imagePicker(_ picker: HEImagePicker, replacingItemWithIdentifer identifier: String) -> HEMediaItem? {
        let imageStore = picker.editImageStore
        do {
            if let hei = imageStore.getHEImage(forAssetIdentifier: identifier) {
                let photo = try hei.toMediaPhoto(imageCache: imageStore)
                return HEMediaItem.photo(p: photo)
            }
        } catch {
            debugPrint(error)
        }
        return nil
    }
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem, inItems items: [HEMediaItem]) {}
    func imagePicker(_ picker: HEImagePicker, didCaptureItem item: HEMediaItem) {}
    
    func imagePicker(_ picker: HEImagePicker, cannotSelectItemType type: PHAssetMediaType?) {
        if type == .image {
            (self as? UIViewController)?.showAlert(PickerConfig.wordings.onlyImageSelectable, confirmAction: nil)
        } else {
            (self as? UIViewController)?.showAlert(PickerConfig.wordings.onlyVideoSelectable, confirmAction: nil)
        }
    }
    
    func imagePicker(_ picker: HEImagePicker, limitExceededOnSelectItemType type: PHAssetMediaType) {
        (self as? UIViewController)?.showAlert(String(format: PickerConfig.wordings.warningMaxItemsLimit, arguments:  [PickerConfig.library.maxNumberOfItems]))
    }
}

/// 이미지 피커
///
/// - 동영상도 됨.
open class HEImagePicker: UINavigationController, HEPickerNavigationController {
    
    public weak var pickerDelegate: HEImagePickerDelegate?
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        PickerConfig.preferredStatusBarStyle
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    /// 편집 이미지 정보 저장소
    public var editImageStore: HEEditImageStore {
        set {
            mainVc.editImageStore = newValue
        }
        get {
            mainVc.editImageStore
        }
    }
    
    public var userInfo: [String: Any] = [:]
    
    private lazy var mainVc: HELibraryViewController = HELibraryViewController()
    
    deinit {
        userInfo = [:]
        lg.trace()
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
    
    private var initiailHEImages: [HEImage] = []
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [mainVc]
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .ypLabel
        view.backgroundColor = .ypSystemBackground
        mainVc.delegate = self
        mainVc.shouldSelectingMediaTypeBlockedCallback = { [weak self] type in
            if let self {
                self.pickerDelegate?.imagePicker(self, cannotSelectItemType: type)
            }
        }
        mainVc.limitExceededCallback = { [weak self] type in
            if let self {
                self.pickerDelegate?.imagePicker(self, limitExceededOnSelectItemType: type)
            }
        }
        
        
        self.initiailHEImages = self.editImageStore.all().map {
            $0.clone(withNewId: $0.id)
        }
        
//        trace("피커 시작")
//        debugPrint(self.editImageStore.all())
//        debugPrint(self.initiailHEImages)
    }
    
    public func reload() {
        mainVc.v.previewBox.reload()
        DispatchQueue.main.async {
            self.mainVc.v.albumCollectionView.reloadData()
        }
    }
}

extension HEImagePicker: HELibraryViewDelegate {
    public func libraryViewHaveNoItems(_ libraryView: HELibraryViewController) {
        pickerDelegate?.imagePickerHaveNoItems(self)
    }
    
    public func libraryView(_ libraryView: HELibraryViewController, didToggleMultipleSelectionEnabled enabled: Bool) {
        lg.trace(enabled)
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
            guard let item = items.first(where: { ($0.phAsset?.localIdentifier ?? $0.identifier) == wantsEditSelection.assetIdentifier }) ?? items.first else {
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
        
        self.editImageStore.clearAll()
        self.editImageStore.addHEImages(self.initiailHEImages)
        
        pickerDelegate?.imagePickerDidCancel(self)
    }
    
}
