//
//  HEAssetZoomableView.swift
//  HEImagePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/16.
//  Edited by Nik Kov || nik-kov.com on 2018/04
//  Ported by 브라운수 on 7/2/24.
//

import UIKit
import Photos
import HECommon

public protocol AssetZoomableViewDelegate: AnyObject {
    func assetZoomableViewDidLayoutSubviews(_ zoomableView: HEAssetZoomableView)
    func assetZoomableViewScrollViewDidZoom()
    func assetZoomableViewScrollViewDidEndZooming()
}

final public class HEAssetZoomableView: UIScrollView {
    public weak var zoomableViewDelegate: AssetZoomableViewDelegate?
    public var cropAreaDidChange = {}
    public private(set) var isVideoMode = false
    public var photoImageView = UIImageView()
    public var videoView = HEVideoView()
    public var squaredZoomScale: CGFloat = 1
    public var minWidthForItem: CGFloat? = PickerConfig.library.minWidthForItem
    
    public fileprivate(set) var currentAssetIdentifier: String?
    public fileprivate(set) var currentAssetType: PHAssetMediaType?
    private var currentEditImageURL: URL?
    private var currentEditTime: TimeInterval?
    
    // Image view of the asset for convenience. Can be video preview image view or photo image view.
    public var assetImageView: UIImageView {
        return isVideoMode ? videoView.previewImageView : photoImageView
    }

    /// Set zoom scale to fit the image to square or show the full image
    //
    /// - Parameters:
    ///   - fit: If true - zoom to show squared. If false - show full.
    public func fitImage(_ fit: Bool, animated isAnimated: Bool = false) {
        squaredZoomScale = calculateSquaredZoomScale()
        if fit {
            setZoomScale(squaredZoomScale, animated: isAnimated)
        } else {
            setZoomScale(1, animated: isAnimated)
        }
    }
    
    /// Re-apply correct scrollview settings if image has already been adjusted in
    /// multiple selection mode so that user can see where they left off.
    public func applyStoredCropPosition(_ scp: HELibrarySelection) {
        // ZoomScale needs to be set first.
        if let zoomScale = scp.scrollViewZoomScale {
            setZoomScale(zoomScale, animated: false)
        }
        if let contentOffset = scp.scrollViewContentOffset {
            setContentOffset(contentOffset, animated: false)
        }
    }
    
    
    // Centring the image frame
    public func centerAssetView() {
        let assetView = isVideoMode ? videoView : photoImageView
        let scrollViewBoundsSize = self.bounds.size
        var assetFrame = assetView.frame
        let assetSize = assetView.frame.size
        
        assetFrame.origin.x = (assetSize.width < scrollViewBoundsSize.width) ?
            (scrollViewBoundsSize.width - assetSize.width) / 2.0 : 0
        assetFrame.origin.y = (assetSize.height < scrollViewBoundsSize.height) ?
            (scrollViewBoundsSize.height - assetSize.height) / 2.0 : 0.0
        
        assetView.frame = assetFrame
    }
    
    public func stopVideoPlay() {
        if currentAssetType == .video {
            videoView.stop()
        }
    }
    
    public func applyVideo(_ video: PHAsset,
                           mediaManager: HELibraryMediaManager?,
                           storedCropPosition: HELibrarySelection?,
                           completion: @escaping () -> Void,
                           updateCropInfo: @escaping () -> Void) {
        guard self.currentAssetIdentifier != video.localIdentifier else { completion() ; return }
        currentAssetType = video.mediaType
        videoView.setPreviewImage(nil)
        photoImageView.removeFromSuperview()
        
        mediaManager?.phImageManager?.fetchPreviewFor(video: video) { [weak self] preview in
            guard let self = self else { return }
            guard self.currentAssetIdentifier != video.localIdentifier else { completion() ; return }
            
            if self.videoView.isDescendant(of: self) == false {
                self.isVideoMode = true
                self.photoImageView.removeFromSuperview()
                self.addSubview(self.videoView)
            }
            
            self.videoView.setPreviewImage(preview)
            
            self.setAssetFrame(for: self.videoView, with: preview)
            
            self.squaredZoomScale = self.calculateSquaredZoomScale()
            
            completion()
            
            // Stored crop position in multiple selection
            if let scp173 = storedCropPosition {
                self.applyStoredCropPosition(scp173)
                // MARK: add update CropInfo after multiple
                updateCropInfo()
            }
        }
        mediaManager?.phImageManager?.fetchPlayerItem(for: video) { [weak self] playerItem in
            guard let self = self else { return }
            guard self.currentAssetIdentifier != video.localIdentifier else { completion() ; return }
            self.currentAssetIdentifier = video.localIdentifier
            self.videoView.durationLabel.text = playerItem.duration.displayTime
            self.videoView.loadVideo(playerItem)
            self.zoomableViewDelegate?.assetZoomableViewDidLayoutSubviews(self)
        }
    }
    
    public func applyImage(_ photo: PHAsset,
                           mediaManager: HELibraryMediaManager?,
                           storedCropPosition: HELibrarySelection?,
                           completion: @escaping (Bool) -> Void,
                           updateCropInfo: @escaping () -> Void) {
        guard currentAssetIdentifier != photo.localIdentifier else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        currentAssetIdentifier = photo.localIdentifier
        currentAssetType = photo.mediaType
        photoImageView.image = nil
        videoView.removeFromSuperview()
        
        mediaManager?.phImageManager?.fetch(photo: photo) { [weak self] image, isLowResIntermediaryImage in
            guard let self = self else { return }
            // Main thread
            if self.photoImageView.isDescendant(of: self) == false {
                self.isVideoMode = false
                self.videoView.removeFromSuperview()
                self.videoView.showPlayImage(show: false)
                self.videoView.deallocate()
                self.addSubview(self.photoImageView)
                
                self.photoImageView.contentMode = .scaleAspectFill
                self.photoImageView.clipsToBounds = true
            }
            
            self.photoImageView.image = image
            if !isLowResIntermediaryImage {
                self.photoImageView.image = image
                if photo.playbackStyle == .imageAnimated {
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    PHImageManager.default().requestImageDataAndOrientation(for: photo, options: options) { [weak self] data, _, _, _ in
                        if let data {
                            self?.photoImageView.he.loadGif(data: data)
                        }
                    }
                }
            }
            self.setAssetFrame(for: self.photoImageView, with: image)
            
            // Stored crop position in multiple selection
            if let scp173 = storedCropPosition {
                self.applyStoredCropPosition(scp173)
                // add update CropInfo after multiple
                updateCropInfo()
            }
            
            self.squaredZoomScale = self.calculateSquaredZoomScale()
            completion(isLowResIntermediaryImage)
        }
    }
    
    public func applyImage(_ hei: HEImage,
                           imageCache: HEImageCache,
                           storedCropPosition: HELibrarySelection?,
                           completion: @escaping (Bool) -> Void,
                           updateCropInfo: @escaping () -> Void) {
        guard (currentAssetIdentifier != hei.id || hei.editImageURL != currentEditImageURL || hei.updatedTime != currentEditTime) else {
            DispatchQueue.main.async { completion(false) }
            return
        }
        currentAssetIdentifier = hei.phAssetIdentifier ?? hei.id
        currentAssetType = .image
        currentEditImageURL = hei.editImageURL
        currentEditTime = hei.updatedTime
        photoImageView.image = nil
        videoView.removeFromSuperview()
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let image: UIImage
                if hei.editImageURL != nil {
                    image = try await imageCache.editImage(forHei: hei).value
                } else {
                    image = try await imageCache.originImage(forHei: hei).value
                }
                DispatchQueue.main.async {
                    if self.photoImageView.isDescendant(of: self) == false {
                        self.isVideoMode = false
                        self.videoView.removeFromSuperview()
                        self.videoView.showPlayImage(show: false)
                        self.videoView.deallocate()
                        self.addSubview(self.photoImageView)
                        
                        self.photoImageView.contentMode = .scaleAspectFill
                        self.photoImageView.clipsToBounds = true
                    }
                    
                    self.photoImageView.image = image
                    self.setAssetFrame(for: self.photoImageView, with: image)
                    // Stored crop position in multiple selection
                    if let scp173 = storedCropPosition {
                        self.applyStoredCropPosition(scp173)
                        // add update CropInfo after multiple
                        updateCropInfo()
                    }
                    
                    self.squaredZoomScale = self.calculateSquaredZoomScale()
                    
                    completion(false)
                }
            } catch {
                woops(error)
                DispatchQueue.main.async {
                    completion(false)                    
                }
            }
        }
    }
    
    public func clearAsset() {
        isVideoMode = false
        videoView.removeFromSuperview()
        videoView.deallocate()
        photoImageView.removeFromSuperview()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        photoImageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        videoView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        maximumZoomScale = 6.0
        minimumZoomScale = 1
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        delegate = self
        alwaysBounceHorizontal = true
        alwaysBounceVertical = true
        isScrollEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        fatalError("Only code layout.")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        zoomableViewDelegate?.assetZoomableViewDidLayoutSubviews(self)
    }
}

// MARK: - Private

fileprivate extension HEAssetZoomableView {
    
    func setAssetFrame(`for` view: UIView, with image: UIImage) {
        // Reseting the previous scale
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        // Calculating and setting the image view frame depending on screenWidth
        let screenWidth = HEImagePickerConfiguration.screenWidth
        
        let w = image.size.width
        let h = image.size.height

        var aspectRatio: CGFloat = 1
        var zoomScale: CGFloat = 1

        if w > h { // Landscape
            aspectRatio = h / w
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth * aspectRatio
        } else if h > w { // Portrait
            aspectRatio = w / h
            view.frame.size.width = screenWidth * aspectRatio
            view.frame.size.height = screenWidth
            
            if let minWidth = minWidthForItem {
                let k = minWidth / screenWidth
                zoomScale = (h / w) * k
            }
        } else { // Square
            view.frame.size.width = screenWidth
            view.frame.size.height = screenWidth
        }
        
        // Centering image view
        view.center = center
        centerAssetView()
        
        // Setting new scale
        self.minimumZoomScale = zoomScale
        self.zoomScale = zoomScale
    }
    
    /// Calculate zoom scale which will fit the image to square
    func calculateSquaredZoomScale() -> CGFloat {
        guard let image = assetImageView.image else {
            trace("No image")
            return 1.0
        }
        
        var squareZoomScale: CGFloat = 1.0
        let w = image.size.width
        let h = image.size.height
        
        if w > h { // Landscape
            squareZoomScale = (w / h)
        } else if h > w { // Portrait
            squareZoomScale = (h / w)
        }
        
        return squareZoomScale
    }
    
}

// MARK: UIScrollViewDelegate Protocol
extension HEAssetZoomableView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return isVideoMode ? videoView : photoImageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomableViewDelegate?.assetZoomableViewScrollViewDidZoom()
        
        centerAssetView()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let view = view, view == photoImageView || view == videoView else { return }
        
        // prevent to zoom out
        if PickerConfig.library.onlySquare && scale < squaredZoomScale {
            self.fitImage(true, animated: true)
        }
        
        zoomableViewDelegate?.assetZoomableViewScrollViewDidEndZooming()
        cropAreaDidChange()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        cropAreaDidChange()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cropAreaDidChange()
    }
}

