//
//  HELibraryViewController+extractSelectedMedia.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/22/24.
//

import Foundation
import Photos
import UIKit
import HECommon

extension HELibraryViewController {
    
    // MARK: 내보내기
    public func extractSelectedMedia(photoCallback: @escaping (_ photo: HEMediaPhoto) -> Void,
                                     videoCallback: @escaping (_ videoURL: HEMediaVideo) -> Void,
                                     multipleItemsCallback: @escaping (_ items: [HEMediaItem]) -> Void) {
        
        exportLoadingView.show(inCenterOf: v)
        v.previewBox.currentZoomableView?.stopVideoPlay()
        
        var previewSelection: [(asset: PHAsset?, hei: HEImage?, cropRect: CGRect?)] = []
        if PickerConfig.allowPickWithoutSelection,
           let identifier = self.v.previewBox.currentZoomableView?.currentAssetIdentifier {
            if let hei = self.editImageStore.getHEImage(forId: identifier) {
                previewSelection = [(nil, hei, nil)]
            } else if let asset = self.assetMediaManager.fetchAsset(assetIdentifier: identifier) {
                previewSelection = [(asset, nil, nil)]
            } else {
                woops("뭐냐??!!")
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            var selectedItems: [(asset: PHAsset?, hei: HEImage?, cropRect: CGRect?)] = self.selectedItems.compactMap {
                if let hei = self.editImageStore.getHEImage(forId: $0.assetIdentifier) {
                    return (nil, hei, $0.cropRect)
                }
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [$0.assetIdentifier], options: PHFetchOptions()).firstObject {
                    return (asset, nil, $0.cropRect)
                }
                woops("뭐냐??!!")
                return nil
            }
            
            if selectedItems.isEmpty {
                selectedItems.append(contentsOf: previewSelection)
            }
            
            if selectedItems.isEmpty {
                DispatchQueue.main.async {
                    self.exportLoadingView.hide()
                }
                return
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
                    
                    self.exportLoadingView.hide()
                    self.libraryViewFinishedLoading()
                }
                // <-- 복수 선택
                
            } else if let item = selectedItems.first { // 단일 선택
                
                if let hei = item.hei {
                    Task {
                        do {
                            let photo = try hei.toMediaPhoto(imageCache: self.editImageStore)
                            if !self.isMultipleSelectionEnabled { // 단일 선택이면, 편집도 단일로 진행
                                self.editImageStore.clearAll()
                                self.editImageStore.addHEImage(hei)
                            }
                            
                            DispatchQueue.main.async { [weak self] in
                                guard let self else { return }
                                self.libraryViewFinishedLoading()
                                self.exportLoadingView.hide()
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
                                guard let self else { return }
                                self.libraryViewFinishedLoading()
                                self.exportLoadingView.hide()
                                if let video {
                                    videoCallback(video)
                                }
                            }
                        }
                        
                    case .image:
                        self.extractPhotoMedia(asset: asset, cropRect: item.cropRect) { photo in
                            DispatchQueue.main.async { [weak self] in
                                guard let self else { return }
                                self.libraryViewFinishedLoading()
                                self.exportLoadingView.hide()
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
                        if !self.isMultipleSelectionEnabled { // 단일 선택이면, 편집도 단일로 진행
                            self.editImageStore.clearAll()
                        }
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
    
    
}
