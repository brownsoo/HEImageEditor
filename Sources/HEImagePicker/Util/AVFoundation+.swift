//
//  AVFileType+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import AVFoundation
import MobileCoreServices

extension AVFileType {
    /// Fetch and extension for a file from UTI string
    var fileExtension: String {
        if let ext = UTType(tag: (self as NSString) as String, tagClass: UTTagClass.filenameExtension, conformingTo: nil) {
            return ext.preferredFilenameExtension ?? "None"
        }
        return "None"
    }
}

extension AVAsset {
    func assetByTrimming(startTime: CMTime, endTime: CMTime) async throws -> AVAsset {
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        let composition = AVMutableComposition()
        do {
            let tracks = try await load(.tracks)
            for track in tracks {
                let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType,
                                                                   preferredTrackID: track.trackID)
                try compositionTrack?.insertTimeRange(timeRange, of: track, at: CMTime.zero)
            }
        } catch let error {
            throw HEPickerError.videoTrimFailed(message: "Error during composition", underlyingError: error)
        }
        
        // Reaply correct transform to keep original orientation.
        if let videoTrack = try? await self.loadTracks(withMediaType: .video).last,
            let compositionTrack = composition.tracks(withMediaType: .video).last {
            let transform = (try? await videoTrack.load(.preferredTransform)) ?? .identity
            compositionTrack.preferredTransform = transform
        }

        return composition
    }
    
    /// Export the video
    ///
    /// - Parameters:
    ///   - destination: The url to export
    ///   - videoComposition: video composition settings, for example like crop
    ///   - removeOldFile: remove old video
    ///   - completion: resulting export closure
    /// - Throws: HEPickerError with description
    func export(to destination: URL,
                videoComposition: AVVideoComposition? = nil,
                removeOldFile: Bool = false,
                progressSession: @escaping (_  exportSession: AVAssetExportSession?) -> Void) async -> AVAssetExportSession? {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: PickerConfig.video.compression) else {
            woops("AVAsset -> Could not create an export session.")
            progressSession(nil)
            return nil
        }
        
        exportSession.outputURL = destination
        exportSession.outputFileType = PickerConfig.video.fileType
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        
        if removeOldFile { try? FileManager.default.removeFileIfNecessary(at: destination) }
        
        progressSession(exportSession)
        
        await exportSession.export()
        return exportSession
    }
}
