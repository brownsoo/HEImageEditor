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

/// The container for asset (video or image). 
/// It containts the HEAssetZoomableView.
final public class HEAssetViewBox: UIView {
    public var zoomableView: HEAssetZoomableView
    public let curtain = UIView()
    public let spinnerView = UIView()
    public private(set) var squareCropButton: UIButton?
    public private(set) var editButton: HECapsuleButton?
    
    public var usingClop = PickerConfig.library.usingClop
    public var isShown = true
    public var spinnerIsShown = false
    
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var shouldCropToSquare = PickerConfig.library.isCropSquareByDefault
    private var isMultipleSelectionEnabled = false

    init(frame: CGRect, zoomableView: HEAssetZoomableView) {
        self.zoomableView = zoomableView
        zoomableView.accessibilityIdentifier = "assetZoomableView"
        super.init(frame: frame)

        
        zoomableView.zoomableViewDelegate = self
        addSubview(zoomableView)
        zoomableView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
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
        zoomableView = HEAssetZoomableView()
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Square button

    @objc public func squareCropButtonTapped() {
        let z = zoomableView.zoomScale
        shouldCropToSquare = (z >= 1 && z < zoomableView.squaredZoomScale)
        zoomableView.fitImage(shouldCropToSquare, animated: true)
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
        guard let selectedAssetImage = zoomableView.assetImageView.image else {
            // If no selected asset, than the squareCropButton is not visible
            squareCropButton?.isHidden = true
            return
        }

        let isImageASquare = selectedAssetImage.size.width == selectedAssetImage.size.height
        squareCropButton?.isHidden = isImageASquare
    }
    
    // MARK: - Multiple selection

    /// Use this to update the multiple selection mode UI state for the YPAssetViewContainer
    public func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        updateSquareCropButtonState()
    }
}

// MARK: - ZoomableViewDelegate
extension HEAssetViewBox: AssetZoomableViewDelegate {
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

// MARK: - Gesture recognizer Delegate
extension HEAssetViewBox: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !spinnerIsShown && !(touch.view is UIButton)
    }
    
}
