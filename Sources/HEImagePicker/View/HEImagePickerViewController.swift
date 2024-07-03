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

/// 이미지 피커 메인 뷰컨트롤러
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
    
    enum Mode {
        case library
        case camera
        case video
    }
    
    
    private lazy var libraryVc = HEPickerLibraryViewController()
    
    var mode: Mode = .library
    var capturedImage: UIImage?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PickerConfig.colors.safeAreaBackgroundColor
        
        libraryVc.delegate = self
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMode()
    }
    
    
    func updateMode() {
        libraryVc.pausePlayer()
        libraryVc.doAfterLibraryPermissionCheck { [weak libraryVc] in
            libraryVc?.initialize()
        }
        
        updateUI()
    }
    
    private func updateUI() {
        if !PickerConfig.hidesCancelButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: imageFromBundle("icArrowRight"),
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(close))
        }
        // TODO: 첨부 갯수
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: PickerConfig.wordings.attach,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
        
        navigationItem.rightBarButtonItem?.setFont(font: PickerConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationItem.rightBarButtonItem?.setFont(font: PickerConfig.fonts.rightBarButtonFont, forState: .disabled)
    }
    
    @objc
    func albumListTapped() {
        guard !libraryVc.isProcessing else {
            return
        }
        
//        let vc = YPAlbumVC(albumsManager: albumsManager)
//        let navVC = UINavigationController(rootViewController: vc)
//        navVC.navigationBar.tintColor = .ypLabel
//        
//        vc.didSelectAlbum = { [weak self] album in
//            self?.libraryVC?.setAlbum(album)
//            self?.setTitleViewWithTitle(aTitle: album.title)
//            navVC.dismiss(animated: true, completion: nil)
//        }
//        present(navVC, animated: true, completion: nil)
    }
    
    @objc
    func close() {
        // Cancelling exporting of all videos
        libraryVc.mediaManager.forseCancelExporting()
        self.didClose?()
    }
    
    @objc
    func done() {
        libraryVc.selectedMedia(photoCallback: { photo in
            self.didSelectItems?([HEMediaItem.photo(p: photo)])
        }, videoCallback: { video in
            self.didSelectItems?([HEMediaItem.video(v: video)])
        }, multipleItemsCallback: { items in
            self.didSelectItems?(items)
        })
    }
}


extension HEImagePickerViewController: HEPickerLibraryViewDelegate {
    public func libraryViewDidTapNext() {
        <#code#>
    }
    
    public func libraryViewStartedLoadingImage() {
        <#code#>
    }
    
    public func libraryViewFinishedLoading() {
        <#code#>
    }
    
    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
        <#code#>
    }
    
    public func libraryViewShouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        <#code#>
    }
    
    public func libraryViewHaveNoItems() {
        <#code#>
    }
    
    public func libraryViewCaption(indexPath: IndexPath) -> String? {
        // TODO:
        return "편집 적용"
    }
    
    
}
