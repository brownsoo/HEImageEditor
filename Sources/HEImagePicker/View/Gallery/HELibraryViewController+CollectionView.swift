//
//  HEPickerLibraryView+CollectionView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import UIKit
import Photos

extension HELibraryViewController {
    
    var isLimitExceeded: Bool { return selectedItems.count >= PickerConfig.library.maxNumberOfItems }
    
    func setupCollectionView() {
        v.albumCollectionView.dataSource = self
        v.albumCollectionView.delegate = self
        v.albumCollectionView.register(HELibraryViewCell.self, forCellWithReuseIdentifier: HELibraryViewCell.reuseIdentifier)
        
    }
        
    internal func getSelectionForJustPreview() -> HELibrarySelection? {
        guard let asset = self.assetMediaManager.fetchResult?.firstObject else {
            return nil
        }
        return HELibrarySelection(assetIdentifier: asset.localIdentifier, isDefaultPreviewing: true)
    }
    
    // MARK: - Library collection view cell managing
    
    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        guard let positionIndex = findIndexInSelectionPool(indexPath: indexPath) else {
            return
        }
        
        selectedItems.remove(at: positionIndex)
        
        if selectedItems.isEmpty { // 선택된 정보가 없다면, 데이터 대체
            v.previewBox.lastPreviwingSelection = getSelectionForJustPreview()
        }
        v.previewBox.removed(at: positionIndex)
        
        // Replace the current selected image with the previously selected one
        if let last = selectedItems.last {
            currentlySelectedIdentifier = last.assetIdentifier
        } else {
            currentlySelectedIdentifier = getSelectionForJustPreview()?.assetIdentifier
        }
        let currentlySelected = currentlySelectedIdentifier
        v.albumCollectionView.visibleCells.compactMap({ $0 as? HELibraryViewCell }).forEach { cell in
            updateLibraryCellUI(cell, currentlySelected: currentlySelected)
        }
        
        checkLimit()
        
    }
    
    /// Adds cell to selection
    @discardableResult
    func addToSelection(indexPath: IndexPath) -> Bool {
        guard let asset = assetMediaManager.getAsset(at: indexPath.row) else {
            print("No asset to add to selection.")
            return false
        }
        
        return addToSelection(localIdentifier: asset.localIdentifier)
    }
    
    @discardableResult
    func addToSelection(localIdentifier: String) -> Bool {
        if isLimitExceeded {
            return false
        }
        
        let shouldBeSelected = delegate?.libraryView(self, shouldAddToSelection: localIdentifier, numSelections: selectedItems.count) ?? true
        if !shouldBeSelected {
            return false
        }

        let newSelection = HELibrarySelection(assetIdentifier: localIdentifier)
        selectedItems.append(newSelection)
        
        checkLimit()
        
        return true
    }
    
    private func isInSelectionPool(indexPath: IndexPath) -> Bool {
        let identifier = assetMediaManager.getAsset(at: indexPath.row)?.localIdentifier
        return selectedItems.contains(where: {
            $0.assetIdentifier == identifier
        })
    }
    
    private func findIndexInSelectionPool(indexPath: IndexPath) -> Int? {
        let identifier = assetMediaManager.getAsset(at: indexPath.row)?.localIdentifier
        return selectedItems.firstIndex(where: {
            $0.assetIdentifier == identifier
        })
    }
    
    private func findIndexPathInCurrentAlbum(identifier: String) -> IndexPath? {
        guard let fetchResult = assetMediaManager.fetchResult else {
            return nil
        }
        var index: Int?
        fetchResult.enumerateObjects { asset, offset, stop in
            if asset.localIdentifier == identifier {
                index = offset
                stop.pointee = true
            }
        }
        
        guard let index else {
            return nil
        }
        return IndexPath(row: index, section: 0)
    }
    
    private func findSelectedIndexPathsInCurrentAlbum() -> [IndexPath] {
        guard let fetchResult = assetMediaManager.fetchResult else {
            return []
        }
        let selections = self.selectedItems.map({ $0.assetIdentifier })
        var results: [IndexPath] = []
        fetchResult.enumerateObjects { asset, offset, _ in
            if selections.contains(where: { $0 == asset.localIdentifier }) {
                results.append(IndexPath(row: offset, section: 0))
            }
        }
        return results
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        updateUI()
    }
}

extension HELibraryViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetMediaManager.fetchResult?.count ?? 0
    }
}

extension HELibraryViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HELibraryViewCell.reuseIdentifier, for: indexPath) as? HELibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        guard let phAsset: PHAsset = assetMediaManager.getAsset(at: indexPath.row) else {
            return cell
        }
        let identifier: String = phAsset.localIdentifier
        var mediaType: PHAssetMediaType
        
        // First thumbnail from external source
        if let heiMedia: HEMediaItem = self.delegate?.libraryView(self, replacingItemWithIdentifer: identifier) {
            switch heiMedia {
            case .photo(let p):
                mediaType = .image
                p.asset = phAsset
                cell.imageLoader = {
                    await p.extraTask?().thumbnail
                }
            case .video(let v):
                mediaType = .video
                v.asset = phAsset
                cell.imageLoader = {
                    await v.thumbnailTask?()
                }
            }
        } else {
            // Original thumbnail from photo album
            mediaType = phAsset.mediaType
            
            let cellSize = v.cellSize()
            let phManager = assetMediaManager.phImageManager
            cell.imageLoader = {
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.isSynchronous = true
                var thumbnail: UIImage?
                phManager?.requestImage(for: phAsset,
                                        targetSize: cellSize,
                                        contentMode: .aspectFill,
                                        options: options) { image, _ in
                    thumbnail = image
                }
                return thumbnail
            }
        }
        
        
        // Info
        cell.bindingAssetIdentifier = identifier
        cell.bindingMediaType = mediaType
        let isVideo = (mediaType == .video)
        if isVideo {
            let duration = UIHelper.formattedStrigFrom(phAsset.duration)
            cell.durationLabel.text = duration
            cell.durationLabel.isHidden = !isVideo || duration.isEmpty
        } else {
            cell.durationLabel.isHidden = true
        }
        
        // updateLibraryCellUI(cell)
        
        return cell
    }
    
    internal func updateLibraryCellUI(_ cell: HELibraryViewCell, currentlySelected: String?) {
        if isMultipleSelectionEnabled {
            cell.multipleSelectionIndicator.isHidden = false
            cell.multipleSelectionIndicator.selectionColor = PickerConfig.colors.multipleItemsSelectedCircleColor ?? PickerConfig.colors.tintColor
            
        } else {
            cell.multipleSelectionIndicator.isHidden = true
        }
        
        cell.isOverlaySelection = cell.bindingAssetIdentifier == currentlySelected
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == cell.bindingAssetIdentifier }) {
            let currentSelection = selectedItems[index]
            selectedItems[index] = HELibrarySelection(
                assetIdentifier: currentSelection.assetIdentifier,
                cropRect: currentSelection.cropRect,
                scrollViewContentOffset: currentSelection.scrollViewContentOffset,
                scrollViewZoomScale: currentSelection.scrollViewZoomScale)
            
            cell.multipleSelectionIndicator.set(number: index + 1) // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.set(number: nil)
        }

        if let caption = delegate?.libraryView(self, captionWithIdentifer: cell.bindingAssetIdentifier) {
            cell.captionLabel.text = caption
            cell.captionLabelFilledHeight?.isActive = true
        } else {
            cell.captionLabel.text = nil
            cell.captionLabelFilledHeight?.isActive = false
        }
        
        // Prevent weird animation where thumbnail fills cell on first scrolls.
        UIView.performWithoutAnimation {
            cell.layoutIfNeeded()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? HELibraryViewCell else { return }
        cell.loadImage()
        //cell.isOverlaySelection = currentlySelectedIdentifier == cell.bindingAssetIdentifier
        updateLibraryCellUI(cell, currentlySelected: self.currentlySelectedIdentifier)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? HELibraryViewCell else { return }
        let previouslySelected = currentlySelectedIdentifier ?? ""
        let currentlySelected = cell.bindingAssetIdentifier
        self.currentlySelectedIdentifier = currentlySelected
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown && PickerConfig.scrollTopIfSelectedWhenPreviewIsHidden {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
         v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelected == currentlySelected
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected || PickerConfig.library.addToSelectionBySigleTouch {
                    self.deselect(indexPath: indexPath)
                    return
                } else {
                    if let index = findIndexInSelectionPool(indexPath: indexPath) {
                        let prevIndex = selectedItems.firstIndex(where: { $0.assetIdentifier == previouslySelected }) ?? index
                        
                        v.previewBox.select(indexInSelection: index, animated: abs(index - prevIndex) < 3)
                    }
                }
            } else if isLimitExceeded == false {
                if addToSelection(indexPath: indexPath) {
                    v.previewBox.inserted(at: selectedItems.count - 1)
                }
            } else if isLimitExceeded {
                // 갯수제한 얼럿 
                showAlert(String(format: PickerConfig.wordings.warningMaxItemsLimit, arguments:  [PickerConfig.library.maxNumberOfItems]))
            }
            
            DispatchQueue.main.async {
                collectionView.visibleCells.compactMap({ $0 as? HELibraryViewCell }).forEach { cell in
                    if cell.bindingAssetIdentifier == previouslySelected || cell.bindingAssetIdentifier == currentlySelected {
                        self.updateLibraryCellUI(cell, currentlySelected: currentlySelected)
                    }
                }
            }
            
        } else {
            selectedItems.removeAll()
            if addToSelection(indexPath: indexPath) {
                v.previewBox.reload()
            }
            // Force deseletion of previously selected cell.
            // In the case where the previous cell was loaded from iCloud, a new image was fetched
            // which triggered photoLibraryDidChange() and reloadItems() which breaks selection.
            //
            if let previouslySelectedIndexPath = findIndexPathInCurrentAlbum(identifier: previouslySelected),
               let previousCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as? HELibraryViewCell {
                previousCell.isOverlaySelection = false
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return isProcessing == false
    }
}

extension HELibraryViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margins = PickerConfig.library.spacingBetweenItems * CGFloat(PickerConfig.library.numberOfItemsInRow - 1)
        let width = (collectionView.frame.width - margins) / CGFloat(PickerConfig.library.numberOfItemsInRow)
        return CGSize(width: width, height: width)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return PickerConfig.library.spacingBetweenItems
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return PickerConfig.library.spacingBetweenItems
    }
}
