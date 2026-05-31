//
//  HEPickerLibraryView+LigraryChanges.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//


import UIKit
import Photos

extension HELibraryViewController: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = self.assetMediaManager.fetchResult,
              let collectionChanges = changeInstance.changeDetails(for: fetchResult) else {
            lg.woops("Some problems there.")
            return
        }

        DispatchQueue.main.async {
            self.v.showLibraryBeingChangeMessage()
            
            let collectionView = self.v.albumCollectionView
            self.assetMediaManager.fetchResult = collectionChanges.fetchResultAfterChanges
            if !collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves {
                collectionView.reloadData()
            } else {
                collectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes,
                       removedIndexes.count != 0 {
                        collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes, insertedIndexes.count != 0 {
                        collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                    }
                }, completion: { finished in
                    guard finished,
                          let changedIndexes = collectionChanges.changedIndexes,
                          changedIndexes.count != 0 else {
                        lg.woops("Some problems there.")
                        return
                    }

                    collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0))
                })
            }

            self.updateAssetSelection()
            self.assetMediaManager.resetCachedAssets()
        }
    }

    fileprivate func updateAssetSelection() {
        lg.trace("라이브러리 갱신")
        var items = self.selectedItems
        if items.count > 0 {
            DispatchQueue.global().async {
                let results = PHAsset.fetchAssets(withLocalIdentifiers: items.map { $0.assetIdentifier }, options: PHFetchOptions())
                items.removeAll { selection in
                    var found = false
                    results.enumerateObjects { asset, _, stop in
                        if asset.localIdentifier == selection.assetIdentifier {
                            found = true
                            stop.pointee = true
                        }
                    }
                    return !found
                }
                
                if self.selectedItems.count != items.count {
                    self.selectedItems = items
                    lg.trace("라이브러리 갱신 후 없어진 어셋 제거")
                    DispatchQueue.main.async {
                        self.v.previewBox.reload()
                        self.v.albumCollectionView.reloadData()
                        self.libraryViewFinishedLoading()
                        
                    }
                }
                
                DispatchQueue.main.async {
                    self.v.hideLibraryBeingChangeMessage()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.v.hideLibraryBeingChangeMessage()
            }
        }
        
//        
//        if self.assetMediaManager.hasResultItems,
//           selectedItems.isEmpty,
//           let _ = self.assetMediaManager.getAsset(at: 0) {
//            trace("선택된게 없어서 기본 선택")
//            addToSelection(indexPath: IndexPath(row: 0, section: 0))
//            DispatchQueue.main.async {
//                self.v.previewBox.reload()
//            }
//        }
//
//        // If user decided to forbid all photos with limited permission
//        // while using the lib we need to remove asset from assets view.
//        if !selectedItems.isEmpty, !self.assetMediaManager.hasResultItems {
//            self.selectedItems.removeAll()
//            self.v.previewBox.reload()
//            self.libraryViewFinishedLoading()
//        }
    }
}
