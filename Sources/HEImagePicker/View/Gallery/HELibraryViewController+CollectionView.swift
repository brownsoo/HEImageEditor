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
        
        // Long press on cell to enable multiple selection
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        v.albumCollectionView.addGestureRecognizer(longPressGR)
    }
    
    /// When tapping on the cell with long press, clear all previously selected cells.
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if isMultipleSelectionEnabled || isProcessing || PickerConfig.library.maxNumberOfItems <= 1 {
            return
        }
        
        if longPressGR.state == .began {
            let point = longPressGR.location(in: v.albumCollectionView)
            guard let indexPath = v.albumCollectionView.indexPathForItem(at: point) else {
                return
            }
            startMultipleSelection(at: indexPath)
        }
    }
    
    private func startMultipleSelection(at indexPath: IndexPath) {
        currentlySelectedIdentifier = (v.albumCollectionView.cellForItem(at: indexPath) as? HELibraryViewCell)?.bindingAssetIdentifier
        toggleMultipleSelection()

        // Bring preview down and keep selected cell visible.
        panGestureHelper.resetToOriginalState()
        if !panGestureHelper.isImageShown {
            v.albumCollectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
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
        
        v.albumCollectionView.visibleCells.compactMap({ $0 as? HELibraryViewCell }).forEach { cell in
            updateLibraryCellUI(cell, identifier: cell.bindingAssetIdentifier)
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
//
//        let tempArray = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count)).map { $0.localIdentifier }
//        let selections = self.selectedItems.map({ $0.assetIdentifier })
//        return tempArray.enumerated().compactMap({
//            selections.contains($0.element) ? IndexPath(row: $0.offset, section: 0) : nil
//        })
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
//        trace(isLimitExceeded || isMultipleSelectionEnabled == false)
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
        trace()
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
        
        updateLibraryCellUI(cell, identifier: identifier)
        
        return cell
    }
    
    private func updateLibraryCellUI(_ cell: HELibraryViewCell, identifier: String) {
        if isMultipleSelectionEnabled {
            cell.multipleSelectionIndicator.isHidden = false
            cell.multipleSelectionIndicator.selectionColor = PickerConfig.colors.multipleItemsSelectedCircleColor ?? PickerConfig.colors.tintColor
            
        } else {
            cell.multipleSelectionIndicator.isHidden = true
        }
        
        cell.isSelected = currentlySelectedIdentifier == identifier
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == identifier }) {
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

        if let caption = delegate?.libraryView(self, captionWithIdentifer: identifier) {
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
        cell.isSelected = currentlySelectedIdentifier == cell.bindingAssetIdentifier
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previouslySelected = currentlySelectedIdentifier ?? ""
        currentlySelectedIdentifier = (collectionView.cellForItem(at: indexPath) as? HELibraryViewCell)?.bindingAssetIdentifier
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown && PickerConfig.scrollTopIfSelectedWhenPreviewIsHidden {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
         v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelected == currentlySelectedIdentifier
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
            
            if let cell = collectionView.cellForItem(at: indexPath) as? HELibraryViewCell {
                updateLibraryCellUI(cell, identifier: cell.bindingAssetIdentifier)
                
                if let previousCell = collectionView.visibleCells.compactMap({ $0 as? HELibraryViewCell }).first(where: { $0.bindingAssetIdentifier == previouslySelected })
                {
                    updateLibraryCellUI(previousCell, identifier: previouslySelected)
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
                previousCell.isSelected = false
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
