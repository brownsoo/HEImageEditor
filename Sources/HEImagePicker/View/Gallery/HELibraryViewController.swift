//
//  HEPickerLibraryView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import Photos
import PhotosUI
import Combine
import HECommon

@MainActor
public protocol HELibraryViewDelegate: AnyObject {
    
    func libraryViewHaveNoItems(_ libraryView: HELibraryViewController)
    func libraryView(_ libraryView: HELibraryViewController, didToggleMultipleSelectionEnabled enabled: Bool)
    /// 앨범 라이브러리에서 선택됨
    func libraryView(_ libraryView: HELibraryViewController, didSelectItems items: [HEMediaItem], wantsEditSelection: HELibrarySelection?)
    /// 카메라를 통해 캡쳐되어 선택됨.
    ///
    /// - PickerConfig.shouldSaveNewPicturesToAlbum 가 false 일 때, 호출된다.
    func libraryView(_ libraryView: HELibraryViewController, didCaptureItem item: HEMediaItem)
    func libraryViewDidCancel(_ libraryView: HELibraryViewController)
    
    func libraryView(_ libraryView: HELibraryViewController, shouldAddToSelection identifier: String, numSelections: Int) -> Bool
    func libraryView(_ libraryView: HELibraryViewController, captionWithIdentifer identifier: String) -> String?
    
    func libraryView(_ libraryView: HELibraryViewController, replacingItemWithIdentifer identifier: String) -> HEMediaItem?
}

/// 피커 본 화면 
public class HELibraryViewController: UIViewController, PermissionCheckable {
    
    override open var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && PickerConfig.hidesStatusBar
    }
    
    public weak var delegate: HELibraryViewDelegate?
    
    public var editImageStore: HEEditImageStore = HESimpleEditImageStore() {
        willSet {
            if isInitialized {
                v.previewBox.editImageStore = newValue
            }
        }
    }
    
    internal var shouldHideStatusBar = false
    internal var initialStatusBarHidden = false
    internal var v = HELibraryView(frame: .zero)
    internal let attachButton = HELibraryAttachButton()
    
    internal var isProcessing = false // true if video or image is in processing state
    internal var selectedItems = [HELibrarySelection]()
    internal let assetMediaManager = HELibraryMediaManager()
    internal var isMultipleSelectionEnabled = false
    internal var currentlySelectedIdentifier: String? = nil
    internal let panGestureHelper = HEPanGestureHelper()
    internal var isInitialized = false
    internal var cancellables = Set<AnyCancellable>()
    
    internal lazy var albumsManager = HEAlbumsManager()
    internal lazy var exportLoadingView = HELoadingView()
    
    // MARK: - Init

    required public init() {
        super.init(nibName: nil, bundle: nil)
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    public override func loadView() {
        view = v
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        pausePlayer()
        
        doAfterLibraryPermissionCheck { [weak self] in
            guard let self else { return }
            
            initialize()
            updateUI()
            
            DispatchQueue.main.async {
                self.correctInitialUI()
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pausePlayer()
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    private func initialize() {
        guard isInitialized == false else {
            return
        }

        defer {
            isInitialized = true
        }

        assetMediaManager.initialize()
        assetMediaManager.exportProgressListener = { [weak self] progress in self?.v.updateProgress(progress) }

        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
        
        v.countButton.addTarget(self, action: #selector(countButtonTapped), for: .touchUpInside)
        v.albumNameBt.addTarget(self, action: #selector(albumListTapped), for: .touchUpInside)
        v.cameraPhotoButton?.addTarget(self, action: #selector(imageCaptureTapped), for: .touchUpInside)
        v.cameraVideoButton?.addTarget(self, action: #selector(videoCaptureTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: PickerConfig.icons.backButtonIcon,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        // 첨부 갯수
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: attachButton)
        attachButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        
        v.previewBox.assetMediaManager = self.assetMediaManager
        v.previewBox.editImageStore = self.editImageStore
        v.previewBox.delegate = self
        
        refreshMediaRequest()
        
        if let preselectedItems = PickerConfig.library.preselectedItems,
           !preselectedItems.isEmpty {
            selectedItems = preselectedItems.compactMap { item -> HELibrarySelection? in
                var itemAsset: PHAsset?
                switch item {
                case .photo(let photo):
                    itemAsset = photo.asset
                case .video(let video):
                    itemAsset = video.asset
                }
                guard let asset = itemAsset else {
                    return nil
                }
                
                // The negative index will be corrected in the collectionView:cellForItemAt:
                return HELibrarySelection(assetIdentifier: asset.localIdentifier)
            }
            v.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
            v.countView.isHidden = !isMultipleSelectionEnabled || selectedItems.isEmpty
            v.albumCollectionView.reloadData()
        }
        
        guard assetMediaManager.hasResultItems else {
            return
        }

        if PickerConfig.library.defaultMultipleSelection || selectedItems.count > 1 {
            toggleMultipleSelection()
        }
    }

    func setAlbum(_ album: HEAlbum) {
        let title = album.collection == nil ? PickerConfig.wordings.allPhotos : album.title
        v.albumNameBt.setTitle(title, for: .normal)
        assetMediaManager.collection = album.collection
        currentlySelectedIdentifier = nil
        refreshMediaRequest()
    }

    
    func updateUI() {
        attachButton.countLabel.text = selectedItems.count > 0 ? String("\(selectedItems.count)") : nil
        
        v.setSelectedCount(selectedItems.count)
        if isProcessing {
            navigationItem.rightBarButtonItem = UIHelper.defaultLoader
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: attachButton)
        }
        
        if let results = assetMediaManager.fetchResult, results.count > 0 {
            v.albumEmptyView.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            v.albumEmptyView.isHidden = false
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    private func correctInitialUI() {
        // Forces assetZoomableView to have a contentSize.
        // otherwise 0 in first selection triggering the bug : "invalid image size 0x0"
        // Also fits the first element to the square if the onlySquareFromLibrary = true
        if !PickerConfig.library.onlySquare && v.previewBox.currentZoomableView?.contentSize == CGSize(width: 0, height: 0) {
            v.previewBox.currentZoomableView?.setZoomScale(1, animated: false)
        }
        
        // Activate multiple selection when using `minNumberOfItems`
        if PickerConfig.library.minNumberOfItems > 1 {
            multipleSelectionButtonTapped()
        }
    }
    
    @objc
    private func countButtonTapped() {
        selectedItems.removeAll()
        v.albumCollectionView.reloadData()
        v.previewBox.reload()
    }
    
    @objc
    private func albumListTapped() {
        guard !isProcessing else {
            return
        }
        let vc = AlbumListViewController(albumsManager: albumsManager)
        let navVC = UINavigationController(rootViewController: vc)
        
        vc.didSelectAlbum = { [weak self] album in
            self?.setAlbum(album)
            navVC.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    @objc
    private func imageCaptureTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            doAfterCameraPermissionCheck { [weak self] in
                guard let self else { return }
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .camera
                picker.mediaTypes = [UTType.image.identifier]
                showDetailViewController(picker, sender: nil)
            }
        } else {
            showAlert(PickerConfig.wordings.noSupportCameraDevice, confirmAction: nil)
        }
    }
    
    @objc
    private func videoCaptureTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            doAfterCameraPermissionCheck { [weak self] in
                guard let self else { return }
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .camera
                picker.mediaTypes = [UTType.movie.identifier]
                showDetailViewController(picker, sender: nil)
            }
        } else {
            showAlert(PickerConfig.wordings.noSupportCameraDevice, confirmAction: nil)
        }
    }
    
    private func didImageCaptured(image: UIImage, exifMeta: [String: Any]?) {
        Task(priority: .userInitiated) { [weak self] in
            do {
                if PickerConfig.shouldSaveNewPicturesToAlbum {
                    try await HEPhotoSaver.trySaveImage(image, inAlbumNamed: PickerConfig.albumName)
                    self?.refreshMediaRequest()
                } else {
                    self?.doneWithNoSavingToAlbum(image: image, exifMeta: exifMeta)
                }
            } catch {
                self?.showAlert(error.localizedDescription)
            }
        }
    }
    
    private func didVideoCaptured(videoURL url: URL) {
        Task(priority: .userInitiated) { [weak self] in
            do {
                if PickerConfig.shouldSaveNewPicturesToAlbum {
                   try await HEPhotoSaver.trySaveVideo(url, inAlbumNamed: PickerConfig.albumName)
                    self?.refreshMediaRequest()
                } else {
                    self?.doneWithNoSavingToAlbum(videoURL: url)
                }
            } catch {
                self?.showAlert(error.localizedDescription)
            }
        }
    }
    
    // 앨범 추가 없이 콜랙션 진행
    private func doneWithNoSavingToAlbum(image: UIImage, exifMeta: [String: Any]?) {
        Task.detached {
            let image = image.resizedImageIfNeeded()
            do {
                let newId = UUID().uuidString
                let url = try await self.editImageStore.cacheOriginImage(uiImage: image, forId: newId).value
                let thumbnail = image.he.thumbnail()
                let photo = HEMediaPhoto(identifier: newId,
                                         url: url,
                                         thumbnail: thumbnail,
                                         exifMeta: exifMeta,
                                         asset: nil)
                await MainActor.run {
                    self.delegate?.libraryView(self, didCaptureItem: .photo(p: photo))
                }
            } catch {
                woops(error)
                await self.showAlert(error.localizedDescription)
            }
        }
    }
    
    
    // 앨범 추가 없이 콜랙션 진행
    private func doneWithNoSavingToAlbum(videoURL url: URL) {
        Task.detached {
            let newId = UUID().uuidString
            let videoItem = HEMediaVideo(identifier: newId,
                                         thumbnail: thumbnailFromVideoPath(url),
                                         videoURL: url,
                                         asset: nil)
            await MainActor.run {
                self.delegate?.libraryView(self, didCaptureItem: .video(v: videoItem))
            }
        }
    }
    
    @objc
    private func close() {
        // Cancelling exporting of all videos
        assetMediaManager.forseCancelExporting()
        delegate?.libraryViewDidCancel(self)
    }
    
    @objc
    private func done() {
        extractSelectedMedia(photoCallback: { [weak self] photo in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.photo(p: photo)], wantsEditSelection: nil)
            }
        }, videoCallback: { [weak self] video in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.video(v: video)], wantsEditSelection: nil)
            }
        }, multipleItemsCallback: { [weak self] items in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: items, wantsEditSelection: nil)
            }
        })
    }
    
    // MARK: - Multiple Selection

    @objc
    func multipleSelectionButtonTapped() {
        // If no items, than preventing multiple selection
        guard assetMediaManager.hasResultItems else {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }
            return
        }

        doAfterLibraryPermissionCheck { [weak self] in
            if self?.isMultipleSelectionEnabled == false {
                self?.selectedItems.removeAll()
            }
            self?.toggleMultipleSelection()
        }
    }
    
    func toggleMultipleSelection() {
        // Prevent desactivating multiple selection when using `minNumberOfItems`
        if PickerConfig.library.minNumberOfItems > 1 && isMultipleSelectionEnabled {
            print("Selected minNumberOfItems greater than one :\(PickerConfig.library.minNumberOfItems). Don't deselecting multiple selection.")
            return
        }

        isMultipleSelectionEnabled.toggle()
        
        if isMultipleSelectionEnabled {
            let currentlySelectedIndex = selectedItems.firstIndex(where: { $0.assetIdentifier == currentlySelectedIdentifier }) ?? 0
            if let asset = assetMediaManager.getAsset(at: currentlySelectedIndex) {
                let needPreselectItemsAndNotSelectedAnyYet = selectedItems.isEmpty && PickerConfig.library.preSelectItemOnMultipleSelection
                let shouldSelectByDelegate: Bool = delegate?.libraryView(self, shouldAddToSelection: asset.localIdentifier, numSelections: selectedItems.count) ?? true
                
                if needPreselectItemsAndNotSelectedAnyYet, 
                    shouldSelectByDelegate {
                    selectedItems = [
                        HELibrarySelection(assetIdentifier: asset.localIdentifier,
                                           cropRect: v.currentCropRect(),
                                           scrollViewContentOffset: v.previewBox.currentZoomableView?.contentOffset,
                                           scrollViewZoomScale: v.previewBox.currentZoomableView?.zoomScale)
                    ]
                }
            }
            
        } else {
            if let last = selectedItems.last {
                selectedItems = [last]
            }
        }
        
        currentlySelectedIdentifier = selectedItems.last?.assetIdentifier ?? getSelectionForJustPreview()?.assetIdentifier
        
        v.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
        v.countView.isHidden = !isMultipleSelectionEnabled || selectedItems.isEmpty
        v.albumCollectionView.reloadData()
        v.previewBox.reload()
        
        checkLimit()
        delegate?.libraryView(self, didToggleMultipleSelectionEnabled: isMultipleSelectionEnabled)
    }
    
    // MARK: - Tap Preview
    
    private func registerForTapOnPreview() {
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.previewBox.addGestureRecognizer(tapImageGesture)
    }
    
    @objc
    private func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    private func refreshMediaRequest() {
        let options = buildPHFetchOptions()

        if let collection = assetMediaManager.collection {
            assetMediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            assetMediaManager.fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        currentlySelectedIdentifier = selectedItems.last?.assetIdentifier
            ?? getSelectionForJustPreview()?.assetIdentifier
        
        var newSelected = false
        if assetMediaManager.hasResultItems,
           let _ = assetMediaManager.getAsset(at: 0) {
            v.albumCollectionView.reloadData()
            if !isLimitExceeded {
                newSelected = true
                v.albumCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition())
                if !isMultipleSelectionEnabled && PickerConfig.library.preSelectItemOnMultipleSelection {
                    addToSelection(indexPath: IndexPath(row: 0, section: 0))
                }
            }
        } else {
            delegate?.libraryViewHaveNoItems(self)
        }
        
        if newSelected || !self.assetMediaManager.hasResultItems {
            DispatchQueue.main.async {
                self.v.previewBox.reload()
            }
        }
        
        scrollToTop()
    }
    
    private func buildPHFetchOptions() -> PHFetchOptions {
        // Sorting condition
        if let userOpt = PickerConfig.library.options {
            return userOpt
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = PickerConfig.library.mediaType.predicate()
        return options
    }
    
    private func scrollToTop() {
        tappedImage()
        v.albumCollectionView.contentOffset = CGPoint.zero
    }
    
    // MARK: - ScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == v.albumCollectionView {
            assetMediaManager.updateCachedAssets(in: self.v.albumCollectionView)
        }
    }
    
    

    // MARK: - Verification
    
    internal func fitsVideoLengthLimits(asset: PHAsset) -> Bool {
        guard asset.mediaType == .video else {
            return true
        }
        
        let tooLong = floor(asset.duration) > PickerConfig.video.libraryTimeLimit
        let tooShort = floor(asset.duration) < PickerConfig.video.minimumTimeLimit
        
        if tooLong || tooShort {
            DispatchQueue.main.async {
                let alert = tooLong ? UIHelper.videoTooLongAlert(self.view) : UIHelper.videoTooShortAlert(self.view)
                self.present(alert, animated: true, completion: nil)
            }
            return false
        }
        
        return true
    }
    
    // MARK: - Stored Crop Position
    
    internal func updateCropInfo(assetIdentifier: String) {
        guard let selectedAssetIndex = selectedItems.firstIndex(where: { $0.assetIdentifier == assetIdentifier }) else {
            return
        }
        
        if selectedItems[selectedAssetIndex].scrollViewContentOffset != nil {
            return
        }
        
        // Fill new values
        var selectedAsset = selectedItems[selectedAssetIndex]
        selectedAsset.scrollViewContentOffset = v.previewBox.currentZoomableView?.contentOffset
        selectedAsset.scrollViewZoomScale = v.previewBox.currentZoomableView?.zoomScale
        selectedAsset.cropRect = v.currentCropRect()
        
        // Replace
        selectedItems.remove(at: selectedAssetIndex)
        selectedItems.insert(selectedAsset, at: selectedAssetIndex)
        
        trace()
        
        //v.previewBox.reload(at: selectedAssetIndex)
    }
    
    // MARK: - Player
    
    func pausePlayer() {
        if let currentZoomableView = v.previewBox.currentZoomableView {
            if currentZoomableView.currentAssetType == .video {
                currentZoomableView.videoView.pause()                
            }
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        v.previewBox.currentZoomableView?.videoView.deallocate()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        trace()
    }
}

extension HELibraryViewController: HEPreviewBoxViewDelegate {
    
    public func previewBoxViewDefaultSelection(_ box: HEPreviewBoxView) -> HELibrarySelection? {
        if let asset = assetMediaManager.getAsset(at: 0) {
            return HELibrarySelection(assetIdentifier: asset.localIdentifier, isDefaultPreviewing: true)
        }
        return nil
    }
    
    public func previewBoxViewItems(_ box: HEPreviewBoxView) -> [HELibrarySelection] {
        return selectedItems
    }
    
    public func previewBoxViewStartedLoadingImage(_ box: HEPreviewBoxView) {
        libraryViewStartedLoadingImage()
    }
    
    public func previewBoxViewFinishedLoadingImage(_ box: HEPreviewBoxView) {
        libraryViewFinishedLoading()
    }
    
    public func previewBoxView(_ box: HEPreviewBoxView, updateCropInfoOfAssetIdentifier assetIdentifier: String) {
        updateCropInfo(assetIdentifier: assetIdentifier)
    }
    
    public func previewBoxView(_ box: HEPreviewBoxView, editButtonTouchedInSelection selection: HELibrarySelection) {
        
        if selection.isJustPreviewing {
            addToSelection(localIdentifier: selection.assetIdentifier)
            v.previewBox.reload()
            v.albumCollectionView.reloadData()
        }
        
        extractSelectedMedia(photoCallback: { [weak self] photo in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.photo(p: photo)], wantsEditSelection: selection)
            }
        }, videoCallback: { [weak self] video in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.video(v: video)], wantsEditSelection: nil)
            }
        }, multipleItemsCallback: { [weak self] items in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: items, wantsEditSelection: selection)
            }
        })
    }
    
    public func previewBoxView(_ box: HEPreviewBoxView, changedCurrentIndex currentIndex: Int) {
        guard let selection = self.selectedItems.get(at: currentIndex),
              (currentlySelectedIdentifier ?? "") != selection.assetIdentifier,
              let fetchResult = assetMediaManager.fetchResult else {
            return
        }
            
        var foundIndex = -1
        fetchResult.enumerateObjects { asset, index, stop in
            if asset.localIdentifier == selection.assetIdentifier {
                foundIndex = index
                stop.pointee = true
            }
        }
        
        if foundIndex > -1 {
            currentlySelectedIdentifier = selection.assetIdentifier
            v.albumCollectionView.visibleCells.compactMap({ $0 as? HELibraryViewCell }).forEach { cell in
                cell.isSelected = cell.representedAssetIdentifier == selection.assetIdentifier
            }
        }
        
    }
}


extension HELibraryViewController {
    func libraryViewDidProcessingNext() {
        isProcessing = true
        DispatchQueue.main.async {
            self.v.previewBox.fadeInLoader()
            self.v.previewBox.isUserInteractionEnabled = false
            self.v.albumCollectionView.isUserInteractionEnabled = false
            self.updateUI()
        }
    }
    
    func libraryViewStartedLoadingImage() {
        // TODO remove to enable changing selection while loading but needs cancelling previous image requests.
        isProcessing = true
    }
    
    func libraryViewFinishedLoading() {
        isProcessing = false
        DispatchQueue.main.async {
            self.v.previewBox.hideLoader()
            self.v.previewBox.isUserInteractionEnabled = true
            self.v.albumCollectionView.isUserInteractionEnabled = true
            self.updateUI()
        }
    }
}


extension HELibraryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        trace(info[.mediaType] as? String) // UTType.movie.identifier or UTType.image.identifier
        picker.dismiss(animated: true)
        
        let fileName: String
        var url: URL?
        let mediaType = info[.mediaType] as? String
        if mediaType == UTType.movie.identifier {
            url = info[.mediaURL] as? URL
        } else if mediaType == UTType.image.identifier {
            url = info[.imageURL] as? URL
        } else {
            return
        }
        
        if let asset = info[.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            fileName = assetResources.first!.originalFilename
        } else {
            if let imageUrl = url {
                fileName = imageUrl.lastPathComponent
            } else {
                fileName = imageTakenGenerateName()
            }
        }
        
        trace(fileName)
        
        if mediaType == UTType.movie.identifier {
            if let url {
                didVideoCaptured(videoURL: url)
            } else {
                let alert = UIHelper.cannotFindMediaAlert(v.cameraVideoButton ?? v.previewBox)
                self.present(alert, animated: true)
            }
        } else if mediaType == UTType.image.identifier {
            if let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) {
                didImageCaptured(image: img, exifMeta: info[.mediaMetadata] as? [String: Any])
            } else if let url {
                Task { [weak self] in
                    do {
                        if let image = try await self?.getImage(forURL: url).value {
                            self?.didImageCaptured(image: image, exifMeta: info[.mediaMetadata] as? [String: Any])
                        }
                    } catch {
                        trace(error)
                        if let self {
                            let alert = UIHelper.cannotFindMediaAlert(v.cameraPhotoButton ?? v.previewBox)
                            self.present(alert, animated: true)
                        }
                    }
                }
            } else {
                let alert = UIHelper.cannotFindMediaAlert(v.cameraPhotoButton ?? v.previewBox)
                self.present(alert, animated: true)
            }
        } else {
            return
        }
    }
    
    func imageTakenGenerateName() -> String {
        return "temp_\(Int(Date().timeIntervalSince1970 * 1000)).png"
    }

    func getImage(forURL url: URL) -> Task<UIImage, Error> {
        Task.detached {
            if url.isFileURL {
                let image = try await Task.detached {
                    let data = try Data(contentsOf: url)
                    return UIImage(data: data)!
                }.value
                return image
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            trace(response)
            if let image = UIImage(data: data) {
                return image
            }
            
            throw HEError.imageNotFound
        }
    }
}
