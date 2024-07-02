//
//  HEImagePickerViewController.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import UIKit
import Photos

protocol HEImagePickerViewDelegate: AnyObject {
    func libraryHasNoItems()
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
}


open class HEImagePickerViewController: UIViewController {
    
    let albumsManager = HEAlbumsManager()
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    weak var delegate: HEImagePickerViewDelegate?
    
    override open var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && PickerConfig.hidesStatusBar
    }
    
    
    /// Private callbacks to YPImagePicker
    public var didClose:(() -> Void)?
    public var didSelectItems: (([HEMediaItem]) -> Void)?
    
    private var libraryVc: HELibraryViewController?
    
}
