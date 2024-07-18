//
//  PHCachingImageManager+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import Photos
import HECommon

extension PHCachingImageManager {
    
    private func photoImageRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.isSynchronous = true // Ok since we're already in a background thread
        return options
    }
    
    func fetchImage(for asset: PHAsset,
                    cropRect: CGRect,
                    targetSize: CGSize,
                    callback: @escaping (UIImage, [String: Any]) -> Void) {
        let options = photoImageRequestOptions()
    
        // Fetch Highiest quality image possible.
        requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data, let image = UIImage(data: data)?.he.fixOrientation() {
            
                // Crop the high quality image manually.
                let xCrop: CGFloat = cropRect.origin.x * CGFloat(asset.pixelWidth)
                let yCrop: CGFloat = cropRect.origin.y * CGFloat(asset.pixelHeight)
                let scaledCropRect = CGRect(x: xCrop,
                                            y: yCrop,
                                            width: targetSize.width,
                                            height: targetSize.height)
                if let imageRef = image.cgImage?.cropping(to: scaledCropRect) {
                    let croppedImage = UIImage(cgImage: imageRef)
                    let exifs = data.he.metadataForImageData()
                    callback(croppedImage, exifs)
                }
            }
        }
    }
    
    func fetchPreviewFor(video asset: PHAsset, callback: @escaping (UIImage) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        let screenWidth = HEImagePickerConfiguration.screenWidth
        let ts = CGSize(width: screenWidth, height: screenWidth)
        requestImage(for: asset, targetSize: ts, contentMode: .aspectFill, options: options) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    callback(image)
                }
            }
        }
    }
    
    func fetchPlayerItem(for video: PHAsset, callback: @escaping (AVPlayerItem) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
        videosOptions.isNetworkAccessAllowed = true
        requestPlayerItem(forVideo: video, options: videosOptions, resultHandler: { playerItem, _ in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    callback(playerItem)
                }
            }
        })
    }
    
    /// This method return two images in the callback. First is with low resolution, second with high.
    /// So the callback fires twice.
    func fetch(photo asset: PHAsset, callback: @escaping (UIImage, Bool) -> Void) {
        let options = PHImageRequestOptions()
        // Enables gettings iCloud photos over the network, this means PHImageResultIsInCloudKey will never be true.
        options.isNetworkAccessAllowed = true
        // Get 2 results, one low res quickly and the high res one later.
        options.deliveryMode = .opportunistic
        requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                     contentMode: .aspectFill, options: options) { result, info in
            guard let image = result else {
                trace("No Result 🛑")
                return
            }
            DispatchQueue.main.async {
                let isLowRes = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                callback(image, isLowRes)
            }
        }
    }
}
