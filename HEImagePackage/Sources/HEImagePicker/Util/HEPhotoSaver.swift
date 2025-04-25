//
//  HEPhotoSaver.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/5/24.
//

import UIKit
import Photos

public class HEPhotoSaver {
    class func trySaveImage(_ image: UIImage, inAlbumNamed: String) async throws {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            do {
                if let album = album(named: inAlbumNamed) {
                   try await saveImage(image, toAlbum: album)
                } else {
                    try? await  createAlbum(withName: inAlbumNamed)
                    if let album = album(named: inAlbumNamed) {
                        try await saveImage(image, toAlbum: album)
                    } else {
                        try PHPhotoLibrary.shared().performChangesAndWait {
                            let _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }
                    }
                }
            } catch {
                throw HEPickerError.custom(message: PickerConfig.wordings.errorOnSaveImageInLibrary, underlyingError: error)
            }
        } else {
            throw HEPickerError.noAuthorization(message: PickerConfig.wordings.noPhotoLibraryAuthor)
        }
    }
    
    class func trySaveVideo(_ videoURL: URL, inAlbumNamed: String) async throws {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            do {
                if let album = album(named: inAlbumNamed) {
                    try await saveVideo(videoURL, toAlbum: album)
                } else {
                    try? await createAlbum(withName: inAlbumNamed)
                    if let album = album(named: inAlbumNamed) {
                        try await saveVideo(videoURL, toAlbum: album)
                    } else {
                        try PHPhotoLibrary.shared().performChangesAndWait {
                            let _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                        }
                    }
                }
            } catch {
                throw HEPickerError.custom(message: PickerConfig.wordings.errorOnSaveVideoInLibrary, underlyingError: error)
            }
        } else {
            throw HEPickerError.noAuthorization(message: PickerConfig.wordings.noPhotoLibraryAuthor)
        }
    }
    
    fileprivate class func saveVideo(_ videoURL: URL, toAlbum album: PHAssetCollection) async throws {
        try PHPhotoLibrary.shared().performChangesAndWait {
            guard let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL) else {
                return
            }
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [changeRequest.placeholderForCreatedAsset!]
            albumChangeRequest?.addAssets(enumeration)
        }
    }
    
    fileprivate class func saveImage(_ image: UIImage, toAlbum album: PHAssetCollection) async throws {
        try PHPhotoLibrary.shared().performChangesAndWait({
            let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [changeRequest.placeholderForCreatedAsset!]
            albumChangeRequest?.addAssets(enumeration)
        })
    }
    
    fileprivate class func createAlbum(withName name: String) async throws {
        try PHPhotoLibrary.shared().performChangesAndWait({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        })
    }
    
    fileprivate class func album(named: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", named)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                 subtype: .any,
                                                                 options: fetchOptions)
        return collection.firstObject
    }
}
