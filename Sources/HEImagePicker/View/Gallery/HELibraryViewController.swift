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
    internal let attachButton = LibraryAttachButton()
    
    internal var isProcessing = false // true if video or image is in processing state
    internal var selectedItems = [HELibrarySelection]()
    internal let assetMediaManager = HELibraryMediaManager()
    internal var isMultipleSelectionEnabled = false
    internal var currentlySelectedIdentifier: String? = nil
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
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        pausePlayer()
        initialize()
        updateUI()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
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

        assetMediaManager.initialize()
        assetMediaManager.exportProgressListener = { [weak self] progress in self?.v.updateProgress(progress) }

        setupCollectionView()
        registerForLibraryChanges()
        panGestureHelper.registerForPanGesture(on: v)
        registerForTapOnPreview()
        
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
        v.countLabel?.text = String(selectedItems.count)
        if isProcessing {
            navigationItem.rightBarButtonItem = UIHelper.defaultLoader
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: attachButton)
        }
    }
    
    
    @objc
    func albumListTapped() {
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
    func imageCaptureTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.mediaTypes = [UTType.image.identifier]
            showDetailViewController(picker, sender: nil)
        } else {
            showAlert(PickerConfig.wordings.noSupportCameraDevice, confirmAction: nil)
        }
    }
    
    @objc
    func videoCaptureTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.mediaTypes = [UTType.movie.identifier]
            showDetailViewController(picker, sender: nil)
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
        let currentlySelectedIndex = selectedItems.firstIndex(where: { $0.assetIdentifier == currentlySelectedIdentifier }) ?? 0
        
        if isMultipleSelectionEnabled {
            let needPreselectItemsAndNotSelectedAnyYet = selectedItems.isEmpty && PickerConfig.library.preSelectItemOnMultipleSelection
            if let asset = assetMediaManager.getAsset(at: currentlySelectedIndex) {
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
            selectedItems.removeAll()
            addToSelection(indexPath: IndexPath(row: currentlySelectedIndex, section: 0))
        }
        
        v.setMultipleSelectionMode(on: isMultipleSelectionEnabled)
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
        
        if newSelected {
            v.previewBox.reload()
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
    
    private func checkVideoFileSize(forAsset asset: PHAsset,
                                    complete: @escaping (_ isValid: Bool) -> Void) {
        guard asset.mediaType == .video else { return complete(true) }
        
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
            guard let asset = asset else {
                complete(true)
                return
            }
            
            if asset.isKind(of: AVComposition.self), ((asset as? AVComposition)?.tracks ?? []).isEmpty {
                complete(true)
                return
            }
            let maxFileSize: Int64 = PickerConfig.video.maxVideoFileSize
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset960x540)
            exportSession?.outputURL = self.fetchOutputURL("TEMP_FOR_SIZE_CHECK")
            exportSession?.fileLengthLimit = maxFileSize
            exportSession?.outputFileType = .mp4
            exportSession?.shouldOptimizeForNetworkUse = true
            exportSession?.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
            
            let estimatedOutputFileLength = exportSession?.estimatedOutputFileLength ?? 0
            print("인코딩전 예상 용량 = \(estimatedOutputFileLength/1024/1024)")
            
            if estimatedOutputFileLength > maxFileSize {
                complete(false)
            } else {
                complete(true)
            }
        }
    }
    
    private func fetchOutputURL(_ fileName: String?) -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let path = documentDirectory.appendingPathComponent(fileName ?? "video.mp4")
        
        return path
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
    
    // MARK: - Fetching Media
    
    private func fetchImageAndCrop(for asset: PHAsset,
                                   withCropRect: CGRect? = nil,
                                   callback: @escaping (_ photo: UIImage, _ exif: [String: Any]) -> Void) {
        libraryViewDidProcessingNext()
        let cropRect = withCropRect ?? DispatchQueue.main.sync { v.currentCropRect() }
        let ts = targetSize(for: asset, cropRect: cropRect)
        assetMediaManager.phImageManager?.fetchImage(for: asset, cropRect: cropRect, targetSize: ts, callback: callback)
    }
    
    private func fetchVideoOriginalURL(for asset: PHAsset,
                                       callback: @escaping (_ videoURL: URL?) -> Void) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl: URL = urlAsset.url as URL
                callback(localVideoUrl)
            } else {
                callback(nil)
            }
        })
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
            DispatchQueue.main.async {
                let alert = UIHelper.videoTooHeavyAlert(self.view)
                self.present(alert, animated: true, completion: nil)
            }
            callback(nil)
            return
        }
        
        checkVideoFileSize(forAsset: asset) { isValid in
            guard isValid else {
                callback(nil)
                return
            }
        }
        
        let trimming = PickerConfig.video.automaticTrimToTrimmerMaxDuration
        
        if trimming {
            let duration = PickerConfig.video.trimmerMaxDuration
            fetchVideoAndCropWithDuration(for: asset,
                                          withCropRect: resultCropRect,
                                          duration: duration,
                                          callback: callback)
        } else {
            libraryViewDidProcessingNext()
            Task {
                let videoURL = await assetMediaManager.fetchVideoUrlAndCrop(for: asset, cropRect: resultCropRect)
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
        libraryViewDidProcessingNext()
        let timeDuration = CMTimeMakeWithSeconds(duration, preferredTimescale: 1000)
        Task {
            let videoURL = await assetMediaManager.fetchVideoUrlAndCropWithDuration(for: asset,
                                                          cropRect: rect,
                                                          duration: timeDuration)
            if Task.isCancelled { return }
            callback(videoURL)
        }
        .store(in: &cancellables)
    }
    
    // MARK: 내보내기
    public func extractSelectedMedia(photoCallback: @escaping (_ photo: HEMediaPhoto) -> Void,
                                     videoCallback: @escaping (_ videoURL: HEMediaVideo) -> Void,
                                     multipleItemsCallback: @escaping (_ items: [HEMediaItem]) -> Void) {
        
        v.previewBox.currentZoomableView?.stopVideoPlay()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let selectedItems: [(asset: PHAsset?, hei: HEImage?, cropRect: CGRect?)] = self.selectedItems.compactMap {
                if let hei = self.editImageStore.getHEImage(forId: $0.assetIdentifier) {
                    return (nil, hei, $0.cropRect)
                }
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier], options: PHFetchOptions()).firstObject {
                    return (asset, nil, $0.cropRect)
                }
                woops("뭐냐??!!")
                return nil
            }
            
            // Multiple selection
            if self.isMultipleSelectionEnabled && self.selectedItems.count > 1 {
                
                // Check video length
                for asset in selectedItems {
                    if let asset = asset.asset, self.fitsVideoLengthLimits(asset: asset) == false {
                        return
                    }
                }
                
                // Fill result media items array
                var resultMediaItems: [HEMediaItem] = []
                let asyncGroup = DispatchGroup()
                
                var assetDictionary: [String?: Int] = .init()
                for (index, itemTuple) in selectedItems.enumerated() {
                    assetDictionary[itemTuple.asset?.localIdentifier ?? itemTuple.hei?.id] = index
                }
                
                for item in selectedItems {
                    asyncGroup.enter()
                    if let hei = item.hei {
                        Task {
                            do {
                                let photo = try hei.toMediaPhoto(imageCache: self.editImageStore)
                                resultMediaItems.append(HEMediaItem.photo(p: photo))
                            } catch {
                                woops(error)
                            }
                            
                            asyncGroup.leave()
                        }
                    }
                    else if let asset = item.asset {
                        switch asset.mediaType {
                        case .image:
                            self.extractPhotoMedia(asset: asset, cropRect: item.cropRect) {  [weak self] photo in
                                guard self != nil else {
                                    asyncGroup.leave()
                                    return
                                }
                                if let photo {
                                    resultMediaItems.append(HEMediaItem.photo(p: photo))
                                }
                                asyncGroup.leave()
                            }
                            
                        case .video:
                            self.extractVideoMedia(asset: asset) {[weak self] video in
                                guard self != nil else {
                                    asyncGroup.leave()
                                    return
                                }
                                if let video {
                                    resultMediaItems.append(HEMediaItem.video(v: video))
                                }
                                asyncGroup.leave()
                            }
                        default:
                            break
                        }
                    } else {
                        asyncGroup.leave()
                    }
                }
                
                asyncGroup.notify(queue: .main) {
                    // TODO: sort the array based on the initial order of the assets in selectedAssets
                    resultMediaItems.sort { (first, second) -> Bool in
                        var firstAsset: String?
                        var secondAsset: String?
                        
                        switch first {
                        case .photo(let photo):
                            firstAsset = photo.identifier
                        case .video(let video):
                            firstAsset = video.identifier
                        }
                        guard let firstIndex = assetDictionary[firstAsset] else {
                            return false
                        }
                        
                        switch second {
                        case .photo(let photo):
                            secondAsset = photo.identifier
                        case .video(let video):
                            secondAsset = video.identifier
                        }
                        
                        guard let secondIndex = assetDictionary[secondAsset] else {
                            return false
                        }
                        
                        return firstIndex < secondIndex
                    }
                    multipleItemsCallback(resultMediaItems)
                    self.libraryViewFinishedLoading()
                }
                // <-- 복수 선택
                
            } else if let item = selectedItems.first { // 단일 선택
                
                if let hei = item.hei {
                   Task {
                       do {
                           let photo = try hei.toMediaPhoto(imageCache: self.editImageStore)
                           DispatchQueue.main.async { [weak self] in
                               self?.libraryViewFinishedLoading()
                               photoCallback(photo)
                           }
                       } catch {
                           woops(error)
                       }
                   }
               } else if let asset = item.asset {
                    switch asset.mediaType {
                    case .audio, .unknown:
                        return
                    case .video:
                        self.extractVideoMedia(asset: asset) { video in
                            DispatchQueue.main.async { [weak self] in
                                self?.libraryViewFinishedLoading()
                                if let video {
                                    videoCallback(video)
                                }
                            }
                        }
                        
                    case .image:
                        self.extractPhotoMedia(asset: asset, cropRect: item.cropRect) { photo in
                            DispatchQueue.main.async { [weak self] in
                                self?.libraryViewFinishedLoading()
                                if let photo {
                                    photoCallback(photo)
                                }
                            }
                        }
                    @unknown default:
                        woops("unknown default reached. Check code.")
                    }
                    return
                }
                else {
                    woops("unknown item data reached. Check code.")
                }
            }
        }
    }
    
    private func extractVideoMedia(asset: PHAsset,
                                   callback: @escaping (HEMediaVideo?) -> Void) {
        switch asset.mediaType {
        case .audio, .unknown:
            return
        case .video:
            if PickerConfig.video.disableCompressing {
                self.fetchVideoOriginalURL(for: asset) { videoURL in
                    if let videoURL = videoURL {
                        DispatchQueue.main.async {
                            let video = HEMediaVideo(identifier: asset.localIdentifier,
                                                     thumbnail: thumbnailFromVideoPath(videoURL),
                                                     videoURL: videoURL,
                                                     asset: asset)
                            callback(video)
                        }
                    } else {
                        self.assetMediaManager.phImageManager?.fetchPreviewFor(video: asset, callback: { thumb in
                            let video = HEMediaVideo(
                                identifier: asset.localIdentifier,
                                thumbnail: thumb,
                                videoURL: URL(string: "http://google.com")!,
                                asset: asset)
                            callback(video)
                        })
                    }
                }
                
            } else {
                self.fetchVideoAndApplySettings(for: asset, callback: { videoURL in
                    DispatchQueue.main.async {
                        if let videoURL = videoURL {
                            let video = HEMediaVideo(identifier: asset.localIdentifier,
                                                     thumbnail: thumbnailFromVideoPath(videoURL),
                                                     videoURL: videoURL,
                                                     asset: asset)
                            callback(video)
                        } else {
                            woops("Problems with fetching videoURL.")
                            callback(nil)
                        }
                    }
                })
            }
        case .image:
            callback(nil)
        @unknown default:
            woops("unknown default reached. Check code.")
            callback(nil)
        }
    }
    
    private func extractPhotoMedia(asset: PHAsset, cropRect: CGRect?,
                                   callback: @escaping (HEMediaPhoto?) -> Void) {
        
        switch asset.mediaType {
        case .audio, .unknown:
            return
        case .video:
            callback(nil)
        case .image:
            self.fetchImageAndCrop(for: asset) { [self] image, exifMeta in
                // cache
                let image = image.resizedImageIfNeeded()
                Task {
                    do {
                        let url = try await editImageStore.cacheOriginImage(uiImage: image, forId: asset.localIdentifier).value
                        self.editImageStore.addHEImage(HEImage(id: asset.localIdentifier, origin: url))
                        let photo = HEMediaPhoto(identifier: asset.localIdentifier,
                                                 url: url,
                                                 thumbnail: image.he.thumbnail(),
                                                 exifMeta: exifMeta,
                                                 asset: asset)
                        DispatchQueue.main.async {
                            callback(photo)
                        }
                    } catch {
                        woops(error)
                        callback(nil)
                    }
                }
            }
        @unknown default:
            woops("unknown default reached. Check code.")
            callback(nil)
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
    public func previewBoxViewUpdateCropInfo(_ box: HEPreviewBoxView, assetIdentifier: String) {
        updateCropInfo(assetIdentifier: assetIdentifier)
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
    
    public func previewBoxViewEditButtonTouched(_ box: HEPreviewBoxView, selection: HELibrarySelection) {
        extractSelectedMedia(photoCallback: { [weak self] photo in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.photo(p: photo)], wantsEditSelection: selection)
            }
        }, videoCallback: { [weak self] video in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: [HEMediaItem.video(v: video)], wantsEditSelection: selection)
            }
        }, multipleItemsCallback: { [weak self] items in
            if let self {
                self.delegate?.libraryView(self, didSelectItems: items, wantsEditSelection: selection)
            }
        })
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
