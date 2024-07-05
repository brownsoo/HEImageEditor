//
//  HEPhotoSaver.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/5/24.
//

import UIKit
import Photos

public class HEPhotoSaver {
    class func trySaveImage(_ image: UIImage, inAlbumNamed: String) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            if let album = album(named: inAlbumNamed) {
                saveImage(image, toAlbum: album)
            } else {
                createAlbum(withName: inAlbumNamed) {
                    if let album = album(named: inAlbumNamed) {
                        saveImage(image, toAlbum: album)
                    }
                }
            }
        }
    }
    
    fileprivate class func saveImage(_ image: UIImage, toAlbum album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [changeRequest.placeholderForCreatedAsset!]
            albumChangeRequest?.addAssets(enumeration)
        })
    }
    
    fileprivate class func createAlbum(withName name: String, completion:@escaping () -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }, completionHandler: { success, _ in
            if success {
                completion()
            }
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
