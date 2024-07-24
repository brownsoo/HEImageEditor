//
//  HEPreviewBoxView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import UIKit
import AVFoundation
import HECommon
import Photos

public protocol HEPreviewBoxViewDelegate: AnyObject {
    func previewBoxViewDefaultSelection(_ box: HEPreviewBoxView) -> HELibrarySelection?
    func previewBoxViewItems(_ box: HEPreviewBoxView) -> [HELibrarySelection]
    func previewBoxViewStartedLoadingImage(_ box: HEPreviewBoxView)
    func previewBoxViewFinishedLoadingImage(_ box: HEPreviewBoxView)
    func previewBoxViewUpdateCropInfo(_ box: HEPreviewBoxView, assetIdentifier: String)
    func previewBoxViewEditButtonTouched(_ box: HEPreviewBoxView, selection: HELibrarySelection)
}

/// The container for asset (video or image). 
/// It containts the collections of HEAssetZoomableView.
public class HEPreviewBoxView: UIView {
    
    public weak var delegate: HEPreviewBoxViewDelegate?
    public weak var editImageStore: HEEditImageStore?
    public weak var assetMediaManager: HELibraryMediaManager?
    
    public let curtain = UIView()
    public let spinnerView = UIView()
    
    public private(set) var editButton: HECapsuleButton?
    public var currentZoomableView: HEAssetZoomableView? {
        if items().isEmpty {
            return nil
        }
        if let cell = collView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? HEPreviewCell {
            return cell.zoomableView
        }
        return nil
    }
    
    public var usingClop = PickerConfig.library.usingClop
    public var isShown = true
    public var spinnerIsShown = false
    private var currentIndex: Int = 0
    
    private(set) internal var collView: UICollectionView!
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var isMultipleSelectionEnabled = false
    
    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.spinnerIsShown = self.shouldShowLoader
            }
        }
    }
    
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PickerConfig.icons.emptyPhotoIcon
        iv.sizeToFit()
        return iv
    }()
    
    /// 미디어 선택없이 미리보기 처리를 위한 플래그
    var lastPreviwingSelection: HELibrarySelection?
    
    deinit {
        trace()
    }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        
        setupCollView()
        
        spinnerView.accessibilityIdentifier = "spinnerView"
        addSubview(spinnerView)
        spinner.accessibilityIdentifier = "spinner"
        spinner.hidesWhenStopped = true
        spinnerView.addSubview(spinner)
        curtain.accessibilityIdentifier = "curtain"
        addSubview(curtain)
        spinner.makeConstraints { v in
            v.centerXAnchorConstraintToSuperview()
            v.centerYAnchorConstraintToSuperview()
        }
        spinnerView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        curtain.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }

        spinner.startAnimating()
        spinnerView.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.3)
        curtain.backgroundColor = UIColor.ypLabel.withAlphaComponent(0.7)
        curtain.alpha = 0

        if PickerConfig.useEditPhoto {
            let button = HECapsuleButton()
            button.setImage(PickerConfig.icons.editImageIcon?.withTintColor(.white), for: .normal)
            button.setTitle(PickerConfig.wordings.editPhoto, for: .normal)
            button.setTitleColor(UIColor(white: 246 / 255.0, alpha: 1.0), for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16 + 4)
            
            button.setBackgroundColor(UIColor(white: 51 / 255.0, alpha: 0.4), for: .normal)
            button.setBackgroundColor(UIColor(white: 151 / 255.0, alpha: 0.6), for: .highlighted)
            addSubview(button)
            button.makeConstraints { v in
                v.bottomAnchorConstraintToSuperview(-24)
                v.centerXAnchorConstraintToSuperview()
            }
            self.editButton = button
            button.isHidden = true
            button.addTarget(self, action: #selector(editPhotoButtonTapped), for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Only code layout.")
    }
    
    @objc
    func editPhotoButtonTapped() {
        let items = items()
        if let item = items.get(at: currentIndex) {
            delegate?.previewBoxViewEditButtonTouched(self, selection: item)
        } else if let first = lastPreviwingSelection {
            delegate?.previewBoxViewEditButtonTouched(self, selection: first)
        }
    }

    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if self.shouldShowLoader {
                self.spinner.isHidden = false
                self.spinner.startAnimating()
                UIView.animate(withDuration: 0.2) {
                    self.spinnerView.alpha = 1
                }
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        spinnerView.alpha = 0
        spinner.isHidden = true
    }
    
    @objc
    func showEditButtonIfNeed(isVideoMode: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showEditButtonIfNeed), object: nil)
        guard let button = editButton, (button.isHidden || button.alpha < 1) else {
            return
        }
        guard let currentZoomableView else {
            return
        }
        trace()
        if currentZoomableView.isVideoMode {
            button.isHidden = true
            // TODO: editing video
            return
        }
        button.isHidden = false
        button.alpha = 0
        button.sizeToFit()
        button.transform = CGAffineTransform(translationX: 0, y: 10)
        button.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.24, delay: 0.1, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            button.alpha = 1
            button.transform = .identity
        })
    }
    
    @objc
    func hideEditButton() {
        trace()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideEditButton), object: nil)
        guard let button = editButton, !button.isHidden else {
            return
        }
        button.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState], animations: {
            button.alpha = 0
        }, completion: { _ in
            button.isHidden = true
        })
    }
    
    private func checkEditButtonShowing() {
        let point = self.convert(collView.center, to: collView)
        if let indexPath = collView.indexPathForItem(at: point) {
            currentIndex = indexPath.row
            if let cell = collView.cellForItem(at: indexPath) as? HEPreviewCell {
                self.perform(#selector(self.showEditButtonIfNeed), with: cell.zoomableView.currentAssetType == .video, afterDelay: 0.2)
            } 
            else if let item = items().get(at: indexPath.row),
                        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.assetIdentifier], options: nil).firstObject {
                self.perform(#selector(self.showEditButtonIfNeed), with: asset.mediaType == .video, afterDelay: 0.2)
            }
        } else {
            currentIndex = 0
        }
    }
    
    // MARK: - Multiple selection

    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        reload()
    }
    
}

// MARK: 미디어 설정
extension HEPreviewBoxView {
    
    private func loadPreviewWithHEImage(_ hei: HEImage?, forCell cell: HEPreviewCell, selection: HELibrarySelection) -> Task<(), Never> {
        Task {
            guard let hei = hei else {
                print("No hei to change.")
                return
            }
            
            delegate?.previewBoxViewStartedLoadingImage(self)
            
            let completion = { [weak self] (isLowResIntermediaryImage: Bool) in
                guard let self else { return }
                if Task.isCancelled { return }
                cell.updateSquareCropButtonState()
                cell.zoomableView.fitImage(true, animated: true)
                self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: hei.id)
                if !isLowResIntermediaryImage {
                    self.hideLoader()
                    self.delegate?.previewBoxViewFinishedLoadingImage(self)
                }
            }
            
            let updateCropInfo = { [weak self] in
                guard let self else { return }
                if Task.isCancelled { return }
                self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: hei.id)
            }
            
            if let editImageStore {
                cell.squareCropButton?.isEnabled = false
                Task.detached {
                    await cell.zoomableView.applyImage(hei,
                                                       imageCache: editImageStore,
                                                       storedCropPosition: selection,
                                                       completion: completion,
                                                       updateCropInfo: updateCropInfo)
                }
            } else {
                woops("편집 이미지 스토어 !!")
            }
        }
    }
    
    private func loadPreview(_ asset: PHAsset?, forCell cell: HEPreviewCell, selection: HELibrarySelection) -> Task<(), Never> {
        
        let isNotSquare = collView.collectionViewLayout is CenteredCellFlowLayout
        
        return Task {
            guard let asset = asset else {
                print("No asset to change.")
                return
            }
            delegate?.previewBoxViewStartedLoadingImage(self)
            let completion = { [weak self] (isLowResIntermediaryImage: Bool) in
                guard let self else { return }
                if Task.isCancelled { return }
                cell.updateSquareCropButtonState()
                cell.zoomableView.fitImage(true, animated: false)
                self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: asset.localIdentifier)
                
                if !isLowResIntermediaryImage {
                    self.hideLoader()
                    self.delegate?.previewBoxViewFinishedLoadingImage(self)
                    DispatchQueue.main.async {
                        if isNotSquare { // 스퀘어가 아니면, 컨텐츠를 가운데로 조정
                            let centerOffsetX = (cell.zoomableView.contentSize.width - cell.contentView.frame.size.width) / 2
                            let centerOffsetY = (cell.zoomableView.contentSize.height - cell.contentView.frame.size.height) / 2
                            let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
                            cell.zoomableView.setContentOffset(centerPoint, animated: false)
        
                        }
                        
                    }
                }
            }
            
            let updateCropInfo = { [weak self] in
                guard let self else { return }
                if Task.isCancelled { return }
                self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: asset.localIdentifier)
            }
            
            // MARK: add a func(updateCropInfo) after crop multiple
            switch asset.mediaType {
            case .image:
                cell.zoomableView.applyImage(asset,
                                             mediaManager: self.assetMediaManager,
                                             storedCropPosition: selection,
                                             completion: completion,
                                             updateCropInfo: updateCropInfo)
                
            case .video:
                cell.zoomableView.applyVideo(asset,
                                             mediaManager: self.assetMediaManager,
                                             storedCropPosition: selection,
                                             completion: { completion(false) },
                                             updateCropInfo: updateCropInfo)
            case .audio, .unknown:
                ()
            @unknown default:
                woops("Bug. Unknown default.")
            }
        }
    }
    
    
    func items() -> [HELibrarySelection] {
        let all = self.delegate?.previewBoxViewItems(self) ?? []
        if all.isEmpty {
            if let it = delegate?.previewBoxViewDefaultSelection(self) { // 기본 미리보기
                return [it]
            }
        }
        return all
    }
    
    func setupCollView() {
        let layout = FullCellFlowLayout()
        layout.scrollDirection = .horizontal
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.collectionViewLayout = layout
        coll.showsHorizontalScrollIndicator = false
        coll.register(HEPreviewCell.self, forCellWithReuseIdentifier: HEPreviewCell.reuseIdentifier)
        coll.isPagingEnabled = false
        addSubview(coll)
        coll.translatesAutoresizingMaskIntoConstraints = false
        coll.edgesConstraintToSuperview(edges: .all)
        coll.backgroundColor = .lightGray
        
        collView = coll
        coll.delegate = self
        coll.dataSource = self
    }
    
    private func changePreviewLayoutIfNeed() {
        let count = items().count
        if count > 1 {
            if !(collView.collectionViewLayout is CenteredCellFlowLayout) {
                let layout = CenteredCellFlowLayout()
                layout.scrollDirection = .horizontal
                collView.collectionViewLayout = layout
                collView.reloadItems(at: [IndexPath(row: 0, section: 0)])
            }
        } else {
            if !(collView.collectionViewLayout is FullCellFlowLayout) {
                let layout = FullCellFlowLayout()
                layout.scrollDirection = .horizontal
                collView.collectionViewLayout = layout
                if count == 1 {
                    collView.reloadItems(at: [IndexPath(row: 0, section: 0)])
                }
            }
        }
        
        if count == 0 {
            collView.backgroundColor = UIColor(white: 238 / 255.0, alpha: 1.0)
            emptyImageView.isHidden = false
            emptyImageView.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
            addSubview(emptyImageView)
        } else {
            collView.backgroundColor = .white
            emptyImageView.isHidden = false
            emptyImageView.removeFromSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkEditButtonShowing()
            
        }
    }
    
    func reload() {
        changePreviewLayoutIfNeed()
        self.collView.reloadData()
    }
    
    func select(_ selection: HELibrarySelection, animated: Bool) {
        if let index = items().firstIndex(where: { $0.assetIdentifier == selection.assetIdentifier }) {
            select(indexInSelection: index, animated: animated)
        }
    }
    
    func select(indexInSelection index: Int, animated: Bool) {
        changePreviewLayoutIfNeed()
        if index < items().count {
            collView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: animated)
        }
    }
    
    func isDefaultPreviewing() -> Bool {
        lastPreviwingSelection?.isJustPreviewing == true
    }
    
    func removed(at index: Int) {
        
        self.perform(#selector(self.hideEditButton), with: nil)
        
        let items = items()
        if index <= items.count && !isDefaultPreviewing() { // dataSource 가 먼저 값이 변경되어 <= 비교
            collView.deleteItems(at: [IndexPath(row: index, section: 0)])
            if index - 1 >= 0 && items.count > 0 {
                collView.scrollToItem(at: IndexPath(row: index - 1, section: 0), at: .centeredHorizontally, animated: true)
            }
            DispatchQueue.main.async {
                self.changePreviewLayoutIfNeed()
            }
        } else {
            reload()
        }
    }
    
    func inserted(at index: Int) {
        self.perform(#selector(self.hideEditButton), with: nil)
        
        let items = items()
        if index < items.count && !isDefaultPreviewing() {
            let indexPath = IndexPath(row: index, section: 0)
            collView.insertItems(at: [indexPath])
            collView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            DispatchQueue.main.async {
                self.changePreviewLayoutIfNeed()
            }
        } else {
            reload()
        }
    }
    
    func reload(at index: Int) {
        let items = items()
        if index < items.count && !items.isEmpty {
            collView.reloadItems(at: [IndexPath(row: index, section: 0)])
        } else {
            collView.reloadData()
        }
    }
    
    
}




// MARK: - Gesture recognizer Delegate
extension HEPreviewBoxView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !spinnerIsShown && !(touch.view is UIButton)
    }
    
}

extension HEPreviewBoxView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items().count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEPreviewCell.reuseIdentifier, for: indexPath) as! HEPreviewCell
        
        let items = self.items()
        cell.isZoomable = items.count < 2
        cell.usingClop = self.usingClop
        if items.count < 2 {
            cell.contentView.layer.cornerRadius = 0
            cell.contentView.layer.masksToBounds = false
        } else {
            cell.contentView.layer.cornerRadius = 12
            cell.contentView.layer.masksToBounds = true
        }
        
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! HEPreviewCell
        if let item = self.items().get(at: indexPath.row) {
            lastPreviwingSelection = item
            
            if cell.bindingIdentifier == item.assetIdentifier {
                if let hei = self.editImageStore?.getHEImage(forId: item.assetIdentifier) {
                    if hei.updatedTime == cell.bindingTime {
                        return
                    }
                } else {
                    return
                }
            }
            cell.bindingIdentifier = item.assetIdentifier
            
            let task = Task {
                trace("미리보기 로드")
                if let hei = self.editImageStore?.getHEImage(forId: item.assetIdentifier) {
                    cell.bindingTime = hei.updatedTime
                    await loadPreviewWithHEImage(hei, forCell: cell, selection: item).value
                } else if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.assetIdentifier], options: PHFetchOptions()).firstObject {
                    cell.bindingTime = asset.creationDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
                    await loadPreview(asset, forCell: cell, selection: item).value
                } else {
                    woops("뭐지?")
                }
                
                // When crop area changes in multiple selection mode,
                // we need to update the scrollView values in order to restore
                // them when user selects a previously selected item.
                cell.zoomableView.cropAreaDidChange = { [weak self] in
                    guard let self else { return }
                    if Task.isCancelled { return }
                    self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: item.assetIdentifier)
                }
            }
            cell.loadTask?.cancel()
            cell.loadTask = task
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! HEPreviewCell
        cell.zoomableView.stopVideoPlay()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.bounds.width
        return CGSize(width: w, height: w)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let _ = editButton {
            hideEditButton()
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        checkEditButtonShowing()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkEditButtonShowing()
    }
}


class HEPreviewCell: UICollectionViewCell {
    static var reuseIdentifier = "he.PreviewCell"
    
    var bindingIdentifier: String?
    var bindingTime: TimeInterval?
    
    lazy var zoomableView = HEAssetZoomableView()
    
    var squareCropButton: UIButton?
    
    var isZoomable: Bool = true {
        didSet {
            if isZoomable {
                zoomableView.isScrollEnabled = true
            } else {
                zoomableView.isScrollEnabled = false
            }
        }
    }
    
    var usingClop: Bool = PickerConfig.library.usingClop {
        didSet {
            updateSquareCropButtonState()
        }
    }
    
    var shouldCropToSquare = PickerConfig.library.isCropSquareByDefault
    var loadTask: Task<(), Never>?
    
    deinit {
        loadTask?.cancel()
        loadTask = nil
        zoomableView.clearAsset()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomableView)
        zoomableView.accessibilityIdentifier = "assetZoomableView"
        zoomableView.zoomableViewDelegate = self
        zoomableView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all, priority: .defaultHigh)
        }
        
        // Crop Button
        let button = UIButton()
        button.setImage(PickerConfig.icons.cropIcon, for: .normal)
        button.backgroundColor = UIColor(white: 51 / 255.0, alpha: 0.2)
        button.layer.cornerRadius = 21
        button.layer.masksToBounds = true
        contentView.addSubview(button)
        button.makeConstraints { v in
            v.sizeAnchorConstraintTo(42)
            v.leadingAnchorConstraintToSuperview(15)
            v.bottomAnchorConstraintToSuperview(-15)
        }
        self.squareCropButton = button
        button.isHidden = !usingClop
        button.addTarget(self, action: #selector(squareCropButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func squareCropButtonTapped() {
        let z = zoomableView.zoomScale
        shouldCropToSquare = (z >= 1 && z < zoomableView.squaredZoomScale)
        zoomableView.fitImage(shouldCropToSquare, animated: true)
    }
    
    /// Update only UI of square crop button.
    public func updateSquareCropButtonState() {
        guard !isZoomable else {
            // If multiple selection enabled, the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }
        guard usingClop else {
            squareCropButton?.isHidden = true
            return
        }
        
        guard let selectedAssetImage = zoomableView.assetImageView.image else {
            // If no selected asset, than the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }

        let isImageASquare = selectedAssetImage.size.width == selectedAssetImage.size.height
        squareCropButton?.isHidden = isImageASquare
    }
}

// MARK: - ZoomableViewDelegate
extension HEPreviewCell: AssetZoomableViewDelegate {
    public func ypAssetZoomableViewDidLayoutSubviews(_ zoomableView: HEAssetZoomableView) {
        // let newFrame = zoomableView.assetImageView.convert(zoomableView.assetImageView.bounds, to: self)
        // Update play imageView position - bringing the playImageView from the videoView to assetViewContainer,
        // but the controll for appearing it still in videoView.
        if zoomableView.videoView.playIconView.isDescendant(of: self) == false {
            self.addSubview(zoomableView.videoView.playIconView)
            zoomableView.videoView.playIconView.centerYAnchorConstraintToSuperview()
            zoomableView.videoView.playIconView.centerXAnchorConstraintToSuperview()
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidZoom() {
    }
    
    public func ypAssetZoomableViewScrollViewDidEndZooming() {
    }
}
