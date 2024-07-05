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

public protocol HEPickerLibraryViewDelegate: AnyObject {
    
    func libraryViewHaveNoItems(_ libraryView: HEPickerLibraryViewController)
    func libraryView(_ libraryView: HEPickerLibraryViewController, didToggleMultipleSelectionEnabled enabled: Bool)
    
    func libraryView(_ libraryView: HEPickerLibraryViewController, didSelectItems items: [HEMediaItem])
    func libraryViewDidCancel(_ libraryView: HEPickerLibraryViewController)
    
    func libraryView(_ libraryView: HEPickerLibraryViewController, shouldAddToSelectionAt indexPath: IndexPath, numSelections: Int) -> Bool
    func libraryView(_ libraryView: HEPickerLibraryViewController, captionAt indexPath: IndexPath) -> String?
    func libraryView(_ libraryView: HEPickerLibraryViewController, replacingItemAt indexPath: IndexPath) -> HEMediaItem?
}

public class HEPickerLibraryViewController: UIViewController, PermissionCheckable {
    
    override open var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && PickerConfig.hidesStatusBar
    }
    
    public weak var delegate: HEPickerLibraryViewDelegate?
    
    internal var shouldHideStatusBar = false
    internal var initialStatusBarHidden = false
    internal var v = LibraryView(frame: .zero)
    internal var isProcessing = false // true if video or image is in processing state
    internal var selectedItems = [HELibrarySelection]()
    internal let mediaManager = LibraryMediaManager()
    internal var isMultipleSelectionEnabled = false
    internal var currentlySelectedIndex: Int = 0
    internal let panGestureHelper = HEPanGestureHelper()
    internal var isInitialized = false
    internal var cancellables = Set<AnyCancellable>()
    
    internal lazy var albumsManager = HEAlbumsManager()
    
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // When crop area changes in multiple selection mode,
        // we need to update the scrollView values in order to restore
        // them when user selects a previously selected item.
        v.assetZoomableView.cropAreaDidChange = { [weak self] in
            guard let self = self else {
                return
            }

            self.updateCropInfo()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        pausePlayer()
        initialize()
        updateUI()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        v.assetViewBox.squareCropButton
            .addTarget(self,
                       action: #selector(squareCropButtonTapped),
                       for: .touchUpInside)
        
        // Forces assetZoomableView to have a contentSize.
        // otherwise 0 in first selection triggering the bug : "invalid image size 0x0"
        // Also fits the first element to the square if the onlySquareFromLibrary = true
        if !PickerConfig.library.onlySquare && v.assetZoomableView.contentSize == CGSize(width: 0, height: 0) {
            v.assetZoomableView.setZoomScale(1, animated: false)
        }
        
        // Activate multiple selection when using `minNumberOfItems`
        if PickerConfig.library.minNumberOfItems > 1 {
            multipleSelectionButtonTapped()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pausePlayer()
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func initialize() {
        guard isInitialized == false else {
            return
        }

        defer {
            isInitialized = true
        }

        mediaManager.initialize()
        mediaManager.exportProgressListener = { [weak self] progress in self?.v.updateProgress(progress) }

        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
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
                return HELibrarySelection(index: -1, assetIdentifier: asset.localIdentifier)
            }
            v.assetViewBox.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
            v.albumCollectionView.reloadData()
        }

        guard mediaManager.hasResultItems else {
            return
        }

        if PickerConfig.library.defaultMultipleSelection || selectedItems.count > 1 {
            toggleMultipleSelection()
        }
    }

    func setAlbum(_ album: HEAlbum) {
        title = album.title
        mediaManager.collection = album.collection
        currentlySelectedIndex = 0
        if !isMultipleSelectionEnabled {
            selectedItems.removeAll()
        }
        refreshMediaRequest()
    }

    
    private func updateUI() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: imageFromBundle("icArrowRight"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
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
        guard !isProcessing else {
            return
        }
        let vc = AlbumListViewController(albumsManager: albumsManager)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.tintColor = .ypLabel
        
        vc.didSelectAlbum = { [weak self] album in
            self?.setAlbum(album)
            navVC.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    @objc
    func cameraCaptureTapped() {
        // PickerConfig.shouldSaveNewPicturesToAlbum
        // TODO: 카메라 촬용
    }
    
    @objc
    private func close() {
        // Cancelling exporting of all videos
        mediaManager.forseCancelExporting()
        delegate?.libraryViewDidCancel(self)
    }
    
    @objc
    private func done() {
        selectedMedia(photoCallback: { [weak self] photo in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.photo(p: photo)])
            }
        }, videoCallback: { [weak self] video in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.video(v: video)])
            }
        }, multipleItemsCallback: { [weak self] items in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: items)
            }
        })
    }
    
    // MARK: - Crop control
    
    @objc
    func squareCropButtonTapped() {
        doAfterLibraryPermissionCheck { [weak self] in
            self?.v.assetViewBox.squareCropButtonTapped()
        }
    }
    
    // MARK: - Multiple Selection

    @objc
    func multipleSelectionButtonTapped() {
        // If no items, than preventing multiple selection
        guard mediaManager.hasResultItems else {
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
            let needPreselectItemsAndNotSelectedAnyYet = selectedItems.isEmpty && PickerConfig.library.preSelectItemOnMultipleSelection
            let shouldSelectByDelegate = delegate?.libraryView(self, shouldAddToSelectionAt: IndexPath(row: currentlySelectedIndex, section: 0), numSelections: selectedItems.count) ?? true
            
            if needPreselectItemsAndNotSelectedAnyYet,
               shouldSelectByDelegate,
               let asset = mediaManager.getAsset(at: currentlySelectedIndex) {
                selectedItems = [
                    HELibrarySelection(index: currentlySelectedIndex,
                                       cropRect: v.currentCropRect(),
                                       scrollViewContentOffset: v.assetZoomableView.contentOffset,
                                       scrollViewZoomScale: v.assetZoomableView.zoomScale,
                                       assetIdentifier: asset.localIdentifier)
                ]
            }
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0))
        }
        
        v.assetViewBox.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
        v.albumCollectionView.reloadData()
        checkLimit()
        delegate?.libraryView(self, didToggleMultipleSelectionEnabled: isMultipleSelectionEnabled)
    }
    
    // MARK: - Tap Preview
    
    func registerForTapOnPreview() {
        let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        v.assetViewBox.addGestureRecognizer(tapImageGesture)
    }
    
    @objc
    func tappedImage() {
        if !panGestureHelper.isImageShown {
            panGestureHelper.resetToOriginalState()
            // no dragup? needed? dragDirection = .up
            v.refreshImageCurtainAlpha()
        }
    }
    
    func refreshMediaRequest() {
        let options = buildPHFetchOptions()

        if let collection = mediaManager.collection {
            mediaManager.fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            mediaManager.fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        if mediaManager.hasResultItems,
        let firstAsset = mediaManager.getAsset(at: 0) {
            changeAsset(firstAsset)
            v.albumCollectionView.reloadData()
            v.albumCollectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                        animated: false,
                                        scrollPosition: UICollectionView.ScrollPosition())
            if !isMultipleSelectionEnabled && PickerConfig.library.preSelectItemOnMultipleSelection {
                addToSelection(indexPath: IndexPath(row: 0, section: 0))
            }
        } else {
            delegate?.libraryViewHaveNoItems(self)
        }

        scrollToTop()
    }
    
    func buildPHFetchOptions() -> PHFetchOptions {
        // Sorting condition
        if let userOpt = PickerConfig.library.options {
            return userOpt
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = PickerConfig.library.mediaType.predicate()
        return options
    }
    
    func scrollToTop() {
        tappedImage()
        v.albumCollectionView.contentOffset = CGPoint.zero
    }
    
    // MARK: - ScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == v.albumCollectionView {
            mediaManager.updateCachedAssets(in: self.v.albumCollectionView)
        }
    }
    
    func changeAsset(_ asset: PHAsset?) {
        guard let asset = asset else {
            print("No asset to change.")
            return
        }

        libraryViewStartedLoadingImage()
        
        let completion = { (isLowResIntermediaryImage: Bool) in
            self.v.assetViewBox.updateSquareCropButtonState()
            self.updateCropInfo()
            if !isLowResIntermediaryImage {
                self.v.hideLoader()
                self.libraryViewFinishedLoading()
            }
        }
        
        let updateCropInfo = {
            self.updateCropInfo()
        }
        
        // MARK: add a func(updateCropInfo) after crop multiple
        DispatchQueue.global(qos: .userInitiated).async {
            switch asset.mediaType {
            case .image:
                self.v.assetZoomableView.setImage(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop(),
                                                  completion: completion,
                                                  updateCropInfo: updateCropInfo)
            case .video:
                self.v.assetZoomableView.setVideo(asset,
                                                  mediaManager: self.mediaManager,
                                                  storedCropPosition: self.fetchStoredCrop(),
                                                  completion: { completion(false) },
                                                  updateCropInfo: updateCropInfo)
            case .audio, .unknown:
                ()
            @unknown default:
                woops("Bug. Unknown default.")
            }
        }
    }

    // MARK: - Verification
    
    private func fitsVideoLengthLimits(asset: PHAsset) -> Bool {
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
    
    internal func updateCropInfo(shouldUpdateOnlyIfNil: Bool = false) {
        guard let selectedAssetIndex = selectedItems.firstIndex(where: { $0.index == currentlySelectedIndex }) else {
            return
        }
        
        if shouldUpdateOnlyIfNil && selectedItems[selectedAssetIndex].scrollViewContentOffset != nil {
            return
        }
        
        // Fill new values
        var selectedAsset = selectedItems[selectedAssetIndex]
        selectedAsset.scrollViewContentOffset = v.assetZoomableView.contentOffset
        selectedAsset.scrollViewZoomScale = v.assetZoomableView.zoomScale
        selectedAsset.cropRect = v.currentCropRect()
        
        // Replace
        selectedItems.remove(at: selectedAssetIndex)
        selectedItems.insert(selectedAsset, at: selectedAssetIndex)
    }
    
    internal func fetchStoredCrop() -> HELibrarySelection? {
        if self.isMultipleSelectionEnabled,
            self.selectedItems.contains(where: { $0.index == self.currentlySelectedIndex }) {
            guard let selectedAssetIndex = self.selectedItems
                .firstIndex(where: { $0.index == self.currentlySelectedIndex }) else {
                return nil
            }
            return self.selectedItems[selectedAssetIndex]
        }
        return nil
    }
    
    internal func hasStoredCrop(index: Int) -> Bool {
        return self.selectedItems.contains(where: { $0.index == index })
    }
    
    // MARK: - Fetching Media
    
    private func fetchImageAndCrop(for asset: PHAsset,
                                   withCropRect: CGRect? = nil,
                                   callback: @escaping (_ photo: UIImage, _ exif: [String: Any]) -> Void) {
        libraryViewDidTapNext()
        let cropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        mediaManager.phImageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoAndApplySettings(for asset: PHAsset,
                                            withCropRect rect: CGRect? = nil,
                                            callback: @escaping (_ videoURL: URL?) -> Void) {
        let normalizedCropRect = rect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: normalizedCropRect)
        let xCrop: CGFloat = normalizedCropRect.origin.x * CGFloat(asset.pixelWidth)
        let yCrop: CGFloat = normalizedCropRect.origin.y * CGFloat(asset.pixelHeight)
        let resultCropRect = CGRect(x: xCrop,
                                    y: yCrop,
                                    width: ts.width,
                                    height: ts.height)
        
        guard fitsVideoLengthLimits(asset: asset) else {
            return
        }
        
        if PickerConfig.video.automaticTrimToTrimmerMaxDuration {
            fetchVideoAndCropWithDuration(for: asset,
                                          withCropRect: resultCropRect,
                                          duration: PickerConfig.video.trimmerMaxDuration,
                                          callback: callback)
        } else {
            libraryViewDidTapNext()
            Task {
                let videoURL = await mediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: resultCropRect)
                if Task.isCancelled { return }
                callback(videoURL)
            }
            .store(in: &cancellables)
        }
    }
    
    private func fetchVideoAndCropWithDuration(for asset: PHAsset,
                                               withCropRect rect: CGRect,
                                               duration: Double,
                                               callback: @escaping (_ videoURL: URL?) -> Void) {
        libraryViewDidTapNext()
        let timeDuration = CMTimeMakeWithSeconds(duration, preferredTimescale: 1000)
        Task {
            let videoURL = await mediaManager.fetchVideoUrlAndCropWithDuration(for: asset,
                                                          cropRect: rect,
                                                          duration: timeDuration)
            if Task.isCancelled { return }
            callback(videoURL)
        }
        .store(in: &cancellables)
    }
    
    public func selectedMedia(photoCallback: @escaping (_ photo: HEMediaPhoto) -> Void,
                              videoCallback: @escaping (_ videoURL: HEMediaVideo) -> Void,
                              multipleItemsCallback: @escaping (_ items: [HEMediaItem]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let selectedAssets: [(asset: PHAsset, cropRect: CGRect?)] = self.selectedItems.compactMap {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier],
                                                      options: PHFetchOptions()).firstObject else {
                    woops("Error!")
                    return nil
                }
                return (asset, $0.cropRect)
            }
            
            // Multiple selection
            if self.isMultipleSelectionEnabled && self.selectedItems.count > 1 {
                
                // Check video length
                for asset in selectedAssets {
                    if self.fitsVideoLengthLimits(asset: asset.asset) == false {
                        return
                    }
                }
                
                // Fill result media items array
                var resultMediaItems: [HEMediaItem] = []
                let asyncGroup = DispatchGroup()
                
                var assetDictionary: [PHAsset?: Int] = .init()
                for (index, assetPair) in selectedAssets.enumerated() {
                    assetDictionary[assetPair.asset] = index
                }
                
                for asset in selectedAssets {
                    asyncGroup.enter()
                    
                    switch asset.asset.mediaType {
                    case .image:
                        self.fetchImageAndCrop(for: asset.asset, withCropRect: asset.cropRect) { image, exifMeta in
                            let photo = HEMediaPhoto(image: image.resizedImageIfNeeded(),
                                                     exifMeta: exifMeta, asset: asset.asset)
                            resultMediaItems.append(HEMediaItem.photo(p: photo))
                            asyncGroup.leave()
                        }
                        
                    case .video:
                        self.fetchVideoAndApplySettings(for: asset.asset,
                                                             withCropRect: asset.cropRect) { videoURL in
                            if let videoURL = videoURL {
                                let videoItem = HEMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                             videoURL: videoURL, asset: asset.asset)
                                resultMediaItems.append(HEMediaItem.video(v: videoItem))
                            } else {
                                woops("Problems with fetching videoURL.")
                            }
                            asyncGroup.leave()
                        }
                    default:
                        break
                    }
                }
                
                asyncGroup.notify(queue: .main) {
                    // TODO: sort the array based on the initial order of the assets in selectedAssets
                    resultMediaItems.sort { (first, second) -> Bool in
                        var firstAsset: PHAsset?
                        var secondAsset: PHAsset?
                        
                        switch first {
                        case .photo(let photo):
                            firstAsset = photo.asset
                        case .video(let video):
                            firstAsset = video.asset
                        }
                        guard let firstIndex = assetDictionary[firstAsset] else {
                            return false
                        }
                        
                        switch second {
                        case .photo(let photo):
                            secondAsset = photo.asset
                        case .video(let video):
                            secondAsset = video.asset
                        }
                        
                        guard let secondIndex = assetDictionary[secondAsset] else {
                            return false
                        }
                        
                        return firstIndex < secondIndex
                    }
                    multipleItemsCallback(resultMediaItems)
                    self.libraryViewFinishedLoading()
                }
            } else {
                let asset = selectedAssets.first!.asset
                switch asset.mediaType {
                case .audio, .unknown:
                    return
                case .video:
                    self.fetchVideoAndApplySettings(for: asset, callback: { videoURL in
                        DispatchQueue.main.async { [weak self] in
                            if let videoURL = videoURL {
                                self?.libraryViewFinishedLoading()
                                let video = HEMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                                         videoURL: videoURL, asset: asset)
                                videoCallback(video)
                            } else {
                                woops("Problems with fetching videoURL.")
                            }
                        }
                    })
                case .image:
                    self.fetchImageAndCrop(for: asset) { image, exifMeta in
                        DispatchQueue.main.async { [weak self] in
                            self?.libraryViewFinishedLoading()
                            let photo = HEMediaPhoto(image: image.resizedImageIfNeeded(),
                                                     exifMeta: exifMeta,
                                                     asset: asset)
                            photoCallback(photo)
                        }
                    }
                @unknown default:
                    woops("unknown default reached. Check code.")
                }
                return
            }
        }
    }
    
    // MARK: - TargetSize
    
    private func targetSize(for asset: PHAsset, cropRect: CGRect) -> CGSize {
        var width = (CGFloat(asset.pixelWidth) * cropRect.width).rounded(.toNearestOrEven)
        var height = (CGFloat(asset.pixelHeight) * cropRect.height).rounded(.toNearestOrEven)
        // round to lowest even number
        width = (width.truncatingRemainder(dividingBy: 2) == 0) ? width : width - 1
        height = (height.truncatingRemainder(dividingBy: 2) == 0) ? height : height - 1
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Player
    
    func pausePlayer() {
        v.assetZoomableView.videoView.pause()
    }
    
    // MARK: - Deinit
    
    deinit {
        v.assetZoomableView.videoView.deallocate()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        trace("\(type(of: self)) deinited 👌🏻")
    }
}


extension HEPickerLibraryViewController {
    func libraryViewDidTapNext() {
        isProcessing = true
        DispatchQueue.main.async {
            self.v.fadeInLoader()
            self.navigationItem.rightBarButtonItem = UIHelper.defaultLoader
        }
    }
    
    func libraryViewStartedLoadingImage() {
        // TODO remove to enable changing selection while loading but needs cancelling previous image requests.
        isProcessing = true
        DispatchQueue.main.async {
            self.v.fadeInLoader()
        }
    }
    
    func libraryViewFinishedLoading() {
        isProcessing = false
        DispatchQueue.main.async {
            self.v.hideLoader()
            self.updateUI()
        }
    }
}
