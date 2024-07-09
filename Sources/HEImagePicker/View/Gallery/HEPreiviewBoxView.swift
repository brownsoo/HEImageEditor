//
//  HEAssetViewBox.swift
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
    func previewBoxViewItems(_ box: HEPreiviewBoxView) -> [HELibrarySelection]
    func previewBoxViewStartedLoadingImage(_ box: HEPreiviewBoxView)
    func previewBoxViewFinishedLoadingImage(_ box: HEPreiviewBoxView)
    func previewBoxViewUpdateCropInfo(_ box: HEPreiviewBoxView, assetIdentifier: String)
}

/// The container for asset (video or image). 
/// It containts the collections of HEAssetZoomableView.
public class HEPreiviewBoxView: UIView {
    
    public weak var delegate: HEPreviewBoxViewDelegate?
    public weak var editImageStore: HEEditImageStore?
    public weak var assetMediaManager: LibraryMediaManager?
    
    public let curtain = UIView()
    public let spinnerView = UIView()
    
    
    public private(set) var editButton: HECapsuleButton?
    private var collView: UICollectionView!
    public var currentZoomableView: HEAssetZoomableView? {
        if (delegate?.previewBoxViewItems(self).isEmpty ?? true) {
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
    private var currentIndex: Int = 0 {
        didSet {
            trace(currentIndex)
        }
    }
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var isMultipleSelectionEnabled = false

    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.spinnerIsShown = self.shouldShowLoader
            }
        }
    }
    
    
    deinit {
        trace()
    }
    
    init() {
        super.init(frame: .zero)
        
        setupCollView()
        
        spinnerView.accessibilityIdentifier = "spinnerView"
        addSubview(spinnerView)
        spinner.accessibilityIdentifier = "spinner"
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
            //button.layer.cornerRadius = 22
            //button.layer.masksToBounds = true
            button.setBackgroundColor(UIColor(white: 51 / 255.0, alpha: 0.4), for: .normal)
            button.setBackgroundColor(UIColor(white: 151 / 255.0, alpha: 0.6), for: .highlighted)
            addSubview(button)
            button.makeConstraints { v in
                v.bottomAnchorConstraintToSuperview(-24)
                v.centerXAnchorConstraintToSuperview()
            }
            self.editButton = button
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                if self.shouldShowLoader == true {
                    UIView.animate(withDuration: 0.2) {
                        self.spinnerView.alpha = 1
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: 0.2) {
                self.spinnerView.alpha = 1
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        spinnerView.alpha = 0
    }
    
    
    // MARK: - Multiple selection

    /// Use this to update the multiple selection mode UI state for the YPAssetViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        reload()
    }
    
}

// MARK: 미디어 설정
extension HEPreiviewBoxView {
    
    private func loadPreviewWithHEImage(_ hei: HEImage?, forCell cell: HEPreviewCell, selection: HELibrarySelection) {
        guard let hei = hei else {
            print("No hei to change.")
            return
        }
        delegate?.previewBoxViewStartedLoadingImage(self)
        
        let completion = { [weak self] (isLowResIntermediaryImage: Bool) in
            guard let self else { return }
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
            self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: hei.id)
        }
        
        if let editImageStore {
            cell.squareCropButton?.isEnabled = false
            DispatchQueue.global(qos: .userInitiated).async {
                cell.zoomableView.applyImage(hei,
                                             imageCache: editImageStore,
                                             storedCropPosition: selection,
                                             completion: completion,
                                             updateCropInfo: updateCropInfo)
            }
        } else {
            woops("편집 이미지 스토어 !!")
        }
    }
    
    func loadPreview(_ asset: PHAsset?, forCell cell: HEPreviewCell, selection: HELibrarySelection) {
        guard let asset = asset else {
            print("No asset to change.")
            return
        }
        
        delegate?.previewBoxViewStartedLoadingImage(self)
        
        let completion = { [weak self] (isLowResIntermediaryImage: Bool) in
            guard let self else { return }
            cell.updateSquareCropButtonState()
            cell.zoomableView.fitImage(true, animated: true)
            self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: asset.localIdentifier)
            if !isLowResIntermediaryImage {
                self.hideLoader()
                self.delegate?.previewBoxViewFinishedLoadingImage(self)
            }
        }
        
        let updateCropInfo = { [weak self] in
            guard let self else { return }
            self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: asset.localIdentifier)
        }
        
        // MARK: add a func(updateCropInfo) after crop multiple
        DispatchQueue.global(qos: .userInitiated).async {
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
}




// MARK: - Gesture recognizer Delegate
extension HEPreiviewBoxView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !spinnerIsShown && !(touch.view is UIButton)
    }
    
}

extension HEPreiviewBoxView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func items() -> [HELibrarySelection] {
        return self.delegate?.previewBoxViewItems(self) ?? []
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
        coll.backgroundColor = .yellow
        
        collView = coll
        coll.delegate = self
        coll.dataSource = self
    }
    
    func changePreviewLayoutIfNeed() {
        if items().count > 1 {
            if !(collView.collectionViewLayout is CenteredCellFlowLayout) {
                let layout = CenteredCellFlowLayout()
                layout.scrollDirection = .horizontal
                collView.collectionViewLayout = layout
            }
        } else {
            if !(collView.collectionViewLayout is FullCellFlowLayout) {
                let layout = FullCellFlowLayout()
                layout.scrollDirection = .horizontal
                collView.collectionViewLayout = layout
            }
        }
    }
    
    func reload() {
        changePreviewLayoutIfNeed()
        self.collView.reloadData()
    }
    
    func select(_ selection: HELibrarySelection, animated: Bool) {
        changePreviewLayoutIfNeed()
        if let index = items().firstIndex(where: { $0.assetIdentifier == selection.assetIdentifier }) {
            collView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: animated)
        }
    }
    
    func removed(at index: Int) {
        let items = items()
        if index <= items.count {
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
        if let items = self.delegate?.previewBoxViewItems(self), index < items.count {
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
        if let items = self.delegate?.previewBoxViewItems(self), index < items.count {
            collView.reloadItems(at: [IndexPath(row: index, section: 0)])
        } else {
            collView.reloadData()
        }
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items().count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEPreviewCell.reuseIdentifier, for: indexPath) as! HEPreviewCell
        cell.isZoomable = collectionView.numberOfItems(inSection: indexPath.section) < 2
        cell.usingClop = self.usingClop
        
        if let item = self.items().get(at: indexPath.row) {
            if let hei = self.editImageStore?.getHEImage(forId: item.assetIdentifier) {
                loadPreviewWithHEImage(hei, forCell: cell, selection: item)
            } else if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.assetIdentifier], options: PHFetchOptions()).firstObject {
                loadPreview(asset, forCell: cell, selection: item)
            } else {
                woops("뭐지?")
            }
            
            // When crop area changes in multiple selection mode,
            // we need to update the scrollView values in order to restore
            // them when user selects a previously selected item.
            cell.zoomableView.cropAreaDidChange = { [weak self] in
                guard let self = self else {
                    return
                }
                self.delegate?.previewBoxViewUpdateCropInfo(self, assetIdentifier: item.assetIdentifier)
            }
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        currentIndex = indexPath.row
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let center = self.convert(collectionView.center, to: collectionView)
        if let index = collectionView.indexPathForItem(at: center) {
            currentIndex = index.row
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.bounds.width
        return CGSize(width: w, height: w)
    }
}


class HEPreviewCell: UICollectionViewCell {
    static var reuseIdentifier = "he.PreviewCell"
    lazy var zoomableView = HEAssetZoomableView()
    var squareCropButton: UIButton?
    
    var isZoomable: Bool = true {
        didSet {
            if isZoomable {
                zoomableView.minimumZoomScale = 1
                zoomableView.maximumZoomScale = 6.0
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
    
    deinit {
        zoomableView.clearAsset()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomableView)
        zoomableView.accessibilityIdentifier = "assetZoomableView"
        zoomableView.zoomableViewDelegate = self
        zoomableView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        
        // Crop Button
        let button = UIButton()
        button.setImage(PickerConfig.icons.cropIcon, for: .normal)
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
        guard !usingClop else {
            // If only square enabled, than the squareCropButton is not visible
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
        if zoomableView.videoView.playImageView.isDescendant(of: self) == false {
            self.addSubview(zoomableView.videoView.playImageView)
            zoomableView.videoView.playImageView.centerYAnchorConstraintToSuperview()
            zoomableView.videoView.playImageView.centerXAnchorConstraintToSuperview()
        }
    }
    
    public func ypAssetZoomableViewScrollViewDidZoom() {
    }
    
    public func ypAssetZoomableViewScrollViewDidEndZooming() {
    }
}
