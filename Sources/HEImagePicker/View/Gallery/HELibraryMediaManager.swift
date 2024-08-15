//
//  LibraryMediaManager.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//


import UIKit
import Photos

/// 포토 라이브러리 미디어 파일 관리 
final public class HELibraryMediaManager {
    
    public var collection: PHAssetCollection?
    public var fetchResult: PHFetchResult<PHAsset>?
    internal var previousPreheatRect: CGRect = .zero
    private (set) var phImageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var currentExportSessions: [AVAssetExportSession] = []

    public var exportProgressListener: ((_ progress: Float) -> Void)?
    
    /// If true then library has items to show. If false the user didn't allow any item to show in picker library.
    public var hasResultItems: Bool {
        if let fetchResult = self.fetchResult {
            return fetchResult.count > 0
        } else {
            return false
        }
    }
    
    public init() {}
    
    public func initialize() {
        phImageManager = PHCachingImageManager()
        resetCachedAssets()
    }
    
    public func resetCachedAssets() {
        phImageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    public func updateCachedAssets(in collectionView: UICollectionView) {
        let screenWidth = HEImagePickerConfiguration.screenWidth
        let size = screenWidth / 4 * UIScreen.main.scale
        let cellSize = CGSize(width: size, height: size)
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            previousPreheatRect.differenceWith(rect: preheatRect, removedHandler: { removedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
            }, addedHandler: { addedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            guard let assetsToStartCaching = fetchResult?.assetsAtIndexPaths(addedIndexPaths),
                  let assetsToStopCaching = fetchResult?.assetsAtIndexPaths(removedIndexPaths) else {
                lg.trace("Some problems in fetching and caching assets.")
                return
            }
            
            phImageManager?.startCachingImages(for: assetsToStartCaching,
                                             targetSize: cellSize,
                                             contentMode: .aspectFill,
                                             options: nil)
            phImageManager?.stopCachingImages(for: assetsToStopCaching,
                                            targetSize: cellSize,
                                            contentMode: .aspectFill,
                                            options: nil)
            previousPreheatRect = preheatRect
        }
    }
    
    public func fetchVideoUrlAndCrop(for videoAsset: PHAsset,
                              cropRect: CGRect) async -> URL? {
        await fetchVideoUrlAndCropWithDuration(for: videoAsset, cropRect: cropRect, duration: nil)
    }
    
    public func fetchVideoUrlAndCropWithDuration(for videoAsset: PHAsset,
                                          cropRect: CGRect,
                                          duration: CMTime?) async -> URL? {
        
        guard let asset = await self.extractAVAsset(for: videoAsset) else {
            lg.woops("Don't have the asset");
            return nil
        }
        
        do {
            let assetComposition = AVMutableComposition()
            let duration: CMTime
            if #available(iOS 15, *) {
                duration = try await asset.load(.duration)
            } else {
                duration = asset.duration
            }
            let assetMaxDuration = self.getMaxVideoDuration(between: duration, andAssetDuration: duration)
            let trackTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: assetMaxDuration)
            
            // 1. Inserting audio and video tracks in composition
            let videoTracks: [AVAssetTrack]
            if #available(iOS 15, *) {
                videoTracks = try await asset.loadTracks(withMediaType: .video)
            } else {
                videoTracks = asset.tracks(withMediaType: AVMediaType.video)
            }
            guard let videoTrack = videoTracks.first,
                  let videoCompositionTrack = assetComposition
                .addMutableTrack(withMediaType: .video,
                                 preferredTrackID: kCMPersistentTrackID_Invalid) else {
                lg.woops("Problems with video track")
                return nil
                
            }
            let audioTracks: [AVAssetTrack]
            if #available(iOS 15, *) {
                audioTracks = try await asset.loadTracks(withMediaType: .audio)
            } else {
                audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
            }
            if let audioTrack = audioTracks.first,
               let audioCompositionTrack = assetComposition
                .addMutableTrack(withMediaType: AVMediaType.audio,
                                 preferredTrackID: kCMPersistentTrackID_Invalid) {
                try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
            }
            
            try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
            
            // Layer Instructions
            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            var transform: CGAffineTransform
            let videoSize: CGSize
            if #available(iOS 15, *) {
                transform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
                videoSize = (try await videoTrack.load(.naturalSize)).applying(transform)
            } else {
                transform = videoTrack.preferredTransform
                videoSize = videoTrack.naturalSize.applying(transform)
            }
            
            transform.tx = (videoSize.width < 0) ? abs(videoSize.width) : 0.0
            transform.ty = (videoSize.height < 0) ? abs(videoSize.height) : 0.0
            transform.tx -= cropRect.minX
            transform.ty -= cropRect.minY
            layerInstructions.setTransform(transform, at: CMTime.zero)
            videoCompositionTrack.preferredTransform = transform
            
            // CompositionInstruction
            let mainInstructions = AVMutableVideoCompositionInstruction()
            mainInstructions.timeRange = trackTimeRange
            mainInstructions.layerInstructions = [layerInstructions]
            
            // Video Composition
            let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
            videoComposition.instructions = [mainInstructions]
            if cropRect.width > 0 && cropRect.height > 0 {
                videoComposition.renderSize = cropRect.size // needed?
            }
            
            // 5. Configuring export session
            
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingUniquePathComponent(pathExtension: PickerConfig.video.fileType.fileExtension)
            let exportedSession = await assetComposition.export(to: fileURL, videoComposition: videoComposition, removeOldFile: true, progressSession: { progressSession in
                if let s = progressSession {
                    self.currentExportSessions.append(s)
                }
                DispatchQueue.main.async {
                    self.exportTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                            target: self,
                                                            selector: #selector(self.onTickExportTimer),
                                                            userInfo: progressSession,
                                                            repeats: true)
                }
            })
            
            guard let exportedSession else {
                lg.woops("Don't have URL.")
                return nil
            }
            
            switch exportedSession.status {
            case .completed:
                if let url = exportedSession.outputURL {
                    if let index = self.currentExportSessions.firstIndex(of: exportedSession) {
                        self.currentExportSessions.remove(at: index)
                    }
                    return url
                } else {
                    lg.woops("Don't have URL.")
                }
            case .failed:
                lg.woops("Export of the video failed : \(String(describing: exportedSession.error))")
            default:
                lg.woops("Export session completed with \(exportedSession.status) status. Not handled.")
            }
            
        } catch let error {
            lg.woops(error)
        }
        return nil
    }
    
    public func extractAVAsset(for videoAsset: PHAsset) async -> AVAsset? {
        guard let phImageManager else { return nil }
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        
        return await withCheckedContinuation { continuation in
            phImageManager.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
                continuation.resume(returning: asset)
            }
        }
    }
    
    public func getMaxVideoDuration(between duration: CMTime?, andAssetDuration assetDuration: CMTime) -> CMTime {
        guard let duration = duration else { return assetDuration }

        if assetDuration <= duration {
            return assetDuration
        } else {
            return duration
        }
    }
    
    @objc func onTickExportTimer(sender: Timer) {
        if let exportSession = sender.userInfo as? AVAssetExportSession {
            if exportSession.progress > 0 {
                exportProgressListener?(exportSession.progress)
            }
            
            if exportSession.progress > 0.99 {
                sender.invalidate()
                exportProgressListener?(0)
                self.exportTimer = nil
            }
        }
    }
    
    public func forseCancelExporting() {
        for s in self.currentExportSessions {
            s.cancelExport()
        }
    }

    public func getAsset(at index: Int) -> PHAsset? {
        guard let fetchResult = fetchResult else {
            print("FetchResult not contain this index: \(index)")
            return nil
        }
        guard fetchResult.count > index else {
            print("FetchResult not contain this index: \(index)")
            return nil
        }
        return fetchResult.object(at: index)
    }
    
    public func fetchAsset(assetIdentifier: String) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: PHFetchOptions()).firstObject
    }
}
