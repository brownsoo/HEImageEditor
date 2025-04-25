//
//  HEAlbumsManager.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import Photos
import UIKit

public struct HEAlbum {
    public var thumbnail: UIImage?
    public var title: String = ""
    public var numberOfItems: Int = 0
    public var collection: PHAssetCollection?
    
    public init(thumbnail: UIImage? = nil, title: String = "", numberOfItems: Int = 0, collection: PHAssetCollection? = nil) {
        self.thumbnail = thumbnail
        self.title = title
        self.numberOfItems = numberOfItems
        self.collection = collection
    }
}


public class HEAlbumsManager {
    
    private var cachedAlbums: [HEAlbum]?
    
    
    /// Collects albums from Photo Library
    /// - Returns: album list
    ///
    /// if PickerConfig.library.mediaType is photo, this collects only photos.
    public func fetchAlbums() -> [HEAlbum] {
        if let cachedAlbums = cachedAlbums {
            return cachedAlbums
        }
        
        var albums = [HEAlbum]()
        let options = PHFetchOptions()
        
        let smartAlbumsResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: options)
        let albumsResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                   subtype: .any,
                                                                   options: options)
        for result in [smartAlbumsResult, albumsResult] {
            result.enumerateObjects({ assetCollection, _, _ in
                var album = HEAlbum()
                album.title = assetCollection.localizedTitle ?? ""
                album.numberOfItems = self.mediaCountFor(collection: assetCollection)
                if album.numberOfItems > 0 {
                    let r = PHAsset.fetchKeyAssets(in: assetCollection, options: nil)
                    if let first = r?.firstObject {
                        let deviceScale = UIScreen.main.scale
                        let targetSize = CGSize(width: 78*deviceScale, height: 78*deviceScale)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.deliveryMode = .opportunistic
                        PHImageManager.default().requestImage(for: first,
                                                              targetSize: targetSize,
                                                              contentMode: .aspectFill,
                                                              options: options,
                                                              resultHandler: { image, _ in
                                                                album.thumbnail = image
                        })
                    }
                    album.collection = assetCollection
                    
                    if PickerConfig.library.mediaType == .photo {
                        if !(assetCollection.assetCollectionSubtype == .smartAlbumSlomoVideos
                            || assetCollection.assetCollectionSubtype == .smartAlbumVideos) {
                            albums.append(album)
                        }
                    } else {
                        albums.append(album)
                    }
                }
            })
        }
        cachedAlbums = albums
        return albums
    }
    
    public func mediaCountFor(collection: PHAssetCollection) -> Int {
        let options = PHFetchOptions()
        options.predicate = PickerConfig.library.mediaType.predicate()
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return result.count
    }
    
}

extension HELibraryMediaType {
    func predicate() -> NSPredicate {
        switch self {
        case .photo:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.image.rawValue)
        case .video:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.video.rawValue)
        case .photoAndVideo:
            return NSPredicate(format: "mediaType = %d || mediaType = %d",
                               PHAssetMediaType.image.rawValue,
                               PHAssetMediaType.video.rawValue)
        }
    }
}
