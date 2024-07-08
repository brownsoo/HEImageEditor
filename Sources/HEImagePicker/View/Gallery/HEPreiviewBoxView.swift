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
    func previewBoxViewUpdateCropInfo(_ box: HEPreiviewBoxView)
}

/// The container for asset (video or image). 
/// It containts the collections of HEAssetZoomableView.
public class HEPreiviewBoxView: UIView {
    
    public weak var delegate: HEPreviewBoxViewDelegate?
    public weak var editImageStore: HEEditImageStore?
    public weak var assetMediaManager: LibraryMediaManager?
    
    public let curtain = UIView()
    public let spinnerView = UIView()
    
    public private(set) var squareCropButton: UIButton?
    public private(set) var editButton: HECapsuleButton?
    private(set) var collView: UICollectionView!
    
    public var usingClop = PickerConfig.library.usingClop
    public var isShown = true
    public var spinnerIsShown = false
    private var currentIndex: Int = 0
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var shouldCropToSquare = PickerConfig.library.isCropSquareByDefault
    private var isMultipleSelectionEnabled = false

    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.squareCropButton?.isEnabled = !self.shouldShowLoader
                self.spinnerIsShown = self.shouldShowLoader
            }
        }
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

        if !usingClop {
            // Crop Button
            let button = UIButton()
            button.setImage(PickerConfig.icons.cropIcon, for: .normal)
            addSubview(button)
            button.makeConstraints { v in
                v.sizeAnchorConstraintTo(42)
                v.leadingAnchorConstraintToSuperview(15)
                v.bottomAnchorConstraintToSuperview(-15)
            }
            self.squareCropButton = button
        }
        
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

    // MARK: - Square button

    @objc public func squareCropButtonTapped() {
        if let cell = collView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? HEPreviewCell {
            let z = cell.zoomableView.zoomScale
            shouldCropToSquare = (z >= 1 && z < cell.zoomableView.squaredZoomScale)
            cell.zoomableView.fitImage(shouldCropToSquare, animated: true)
        }
    }

    /// Update only UI of square crop button.
    public func updateSquareCropButtonState() {
        guard !isMultipleSelectionEnabled else {
            // If multiple selection enabled, the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }
        guard !usingClop else {
            // If only square enabled, than the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }
        
        guard let cell = collView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? HEPreviewCell else {
            return
        }
        guard let selectedAssetImage = cell.zoomableView.assetImageView.image else {
            // If no selected asset, than the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }

        let isImageASquare = selectedAssetImage.size.width == selectedAssetImage.size.height
        squareCropButton?.isHidden = isImageASquare
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
        updateSquareCropButtonState()
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
            self.updateSquareCropButtonState()
            self.delegate?.previewBoxViewUpdateCropInfo(self)
            if !isLowResIntermediaryImage {
                self.hideLoader()
                self.delegate?.previewBoxViewFinishedLoadingImage(self)
            }
        }
        
        let updateCropInfo = { [weak self] in
            guard let self else { return }
            self.delegate?.previewBoxViewUpdateCropInfo(self)
        }
        
        if let editImageStore {
            DispatchQueue.global(qos: .userInitiated).async {
                cell.zoomableView.applyImage(hei,
                                             imageCache: editImageStore,
                                             storedCropPosition: selection,
                                             completion: completion,
                                             updateCropInfo: updateCropInfo)
            }
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
            self.updateSquareCropButtonState()
            self.delegate?.previewBoxViewUpdateCropInfo(self)
            if !isLowResIntermediaryImage {
                self.hideLoader()
                self.delegate?.previewBoxViewFinishedLoadingImage(self)
            }
        }
        
        let updateCropInfo = { [weak self] in
            guard let self else { return }
            self.delegate?.previewBoxViewUpdateCropInfo(self)
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
    
    func setupCollView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.collectionViewLayout = layout
        coll.showsHorizontalScrollIndicator = false
        coll.register(HEPreviewCell.self, forCellWithReuseIdentifier: HEPreviewCell.reuseIdentifier)
        coll.isPagingEnabled = true
        addSubview(coll)
        coll.translatesAutoresizingMaskIntoConstraints = false
        coll.edgesConstraintToSuperview(edges: .all)
        
        collView = coll
        coll.delegate = self
        coll.dataSource = self
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.delegate?.previewBoxViewItems(self).count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEPreviewCell.reuseIdentifier, for: indexPath) as! HEPreviewCell
        if let item = self.delegate?.previewBoxViewItems(self)[indexPath.row] {
            if let hei = self.editImageStore?.getHEImage(forId: item.assetIdentifier) {
                loadPreviewWithHEImage(hei, forCell: cell, selection: item)
            } else if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [item.assetIdentifier], options: PHFetchOptions()).firstObject {
                loadPreview(asset, forCell: cell, selection: item)
            } else {
                woops("뭐지?")
            }
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        currentIndex = indexPath.row
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? HEPreviewCell)?.zoomableView.clearAsset()
        
        let center = self.convert(collectionView.center, to: collectionView)
        if let index = collectionView.indexPathForItem(at: center) {
            currentIndex = indexPath.row
        }
        
    }
}


class HEPreviewCell: UICollectionViewCell {
    static var reuseIdentifier = "he.PreviewCell"
    lazy var zoomableView = HEAssetZoomableView()
    
    var isZoomable: Bool = true {
        didSet {
            if isZoomable {
                zoomableView.minimumZoomScale = 1
                zoomableView.maximumZoomScale = 6.0
            } else {
                zoomableView.setZoomScale(1.0, animated: self.superview != nil)
                zoomableView.minimumZoomScale = 1
                zoomableView.maximumZoomScale = 1
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(zoomableView)
        zoomableView.accessibilityIdentifier = "assetZoomableView"
        zoomableView.zoomableViewDelegate = self
        zoomableView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
