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
        v.albumCollectionView.register(LibraryViewCell.self, forCellWithReuseIdentifier: LibraryViewCell.reuseIdentifier)
        
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
        currentlySelectedIdentifier = (v.albumCollectionView.cellForItem(at: indexPath) as? LibraryViewCell)?.representedAssetIdentifier
        toggleMultipleSelection()

        // Bring preview down and keep selected cell visible.
        panGestureHelper.resetToOriginalState()
        if !panGestureHelper.isImageShown {
            v.albumCollectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
    }
    
    // MARK: - Library collection view cell managing
    
    /// Removes cell from selection
    func deselect(indexPath: IndexPath) {
        if let positionIndex = findIndexInSelectionPool(indexPath: indexPath) {
            selectedItems.remove(at: positionIndex)
            v.previewBox.removed(at: positionIndex)
            // Refresh the numbers
            let selectedIndexPaths = findSelectedIndexPathsInCurrentAlbum()
            v.albumCollectionView.reloadItems(at: selectedIndexPaths)
            
            // Replace the current selected image with the previously selected one
            if let last = selectedItems.last {
                v.albumCollectionView.deselectItem(at: indexPath, animated: false)
                if let previouslySelectedIndexPath = findIndexPathInCurrentAlbum(identifier: last.assetIdentifier) {
                    v.albumCollectionView.selectItem(at: previouslySelectedIndexPath, animated: false, scrollPosition: [])
                }
                currentlySelectedIdentifier = last.assetIdentifier
            }
            
            if let last = selectedItems.last {
                v.previewBox.select(last, animated: true)
            }
            
            checkLimit()
        }
    }
    
    /// Adds cell to selection
    func addToSelection(indexPath: IndexPath) {
        let shouldBeSelected = delegate?.libraryView(self, shouldAddToSelectionAt: indexPath, numSelections: selectedItems.count) ?? true
        if !shouldBeSelected {
            return
        }
        guard let asset = assetMediaManager.getAsset(at: indexPath.row) else {
            print("No asset to add to selection.")
            return
        }

        let newSelection = HELibrarySelection(assetIdentifier: asset.localIdentifier)
        selectedItems.append(newSelection)
        
        checkLimit()
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
        let tempArray = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))
        guard let index = tempArray.firstIndex(where: { $0.localIdentifier == identifier }) else {
            return nil
        }
        return IndexPath(row: index, section: 0)
    }
    
    private func findSelectedIndexPathsInCurrentAlbum() -> [IndexPath] {
        guard let fetchResult = assetMediaManager.fetchResult else {
            return []
        }
        let tempArray = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count)).map { $0.localIdentifier }
        let selections = self.selectedItems.map({ $0.assetIdentifier })
        return tempArray.enumerated().compactMap({
            selections.contains($0.element) ? IndexPath(row: $0.offset, section: 0) : nil
        })
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryViewCell.reuseIdentifier, for: indexPath) as? LibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        
        var identifier: String
        var mediaType: PHAssetMediaType
        var phAsset: PHAsset?
        var thumbnail: UIImage?
        // Original thumbnail from photo album
        if let asset = assetMediaManager.getAsset(at: indexPath.row) {
            identifier = asset.localIdentifier
            mediaType = asset.mediaType
            phAsset = asset
        } else {
            return cell
        }
        // Replacing thumbnail from external source
        if let asset = phAsset, let media = delegate?.libraryView(self, replacingItemWithIdentifer: asset.localIdentifier) {
            switch media {
            case .photo(let photo):
                identifier = photo.identifier
                mediaType = .image
                phAsset = photo.asset
                thumbnail = photo.thumbnail
            case .video(let video):
                identifier = video.identifier
                mediaType = .video
                phAsset = video.asset
                thumbnail = video.thumbnail
            }
        }
        
        // Load Image
        
        if let phAsset {
            assetMediaManager.phImageManager?.requestImage(for: phAsset,
                                                      targetSize: v.cellSize(),
                                                      contentMode: .aspectFill,
                                                      options: nil) { image, _ in
                // The cell may have been recycled when the time this gets called
                // set image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == phAsset.localIdentifier && image != nil {
                    cell.imageView.image = image
                }
            }
        } else {
            cell.imageView.image = thumbnail
        }

        // Info
        cell.representedAssetIdentifier = identifier
        cell.multipleSelectionIndicator.selectionColor = PickerConfig.colors.multipleItemsSelectedCircleColor ?? PickerConfig.colors.tintColor
        
        
        let isVideo = (mediaType == .video)
        if let asset = phAsset {
            let duration = isVideo ? UIHelper.formattedStrigFrom(asset.duration) : ""
            cell.durationLabel.text = duration
            cell.durationLabel.isHidden = !isVideo || duration.isEmpty
        } else {
            cell.durationLabel.text = nil
            cell.durationLabel.isHidden = true
        }
        cell.multipleSelectionIndicator.isHidden = !isMultipleSelectionEnabled
        cell.isSelected = currentlySelectedIdentifier == identifier
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == identifier }) {
            let currentSelection = selectedItems[index]
            selectedItems[index] = HELibrarySelection(assetIdentifier: currentSelection.assetIdentifier,
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
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previouslySelected = currentlySelectedIdentifier ?? ""
        currentlySelectedIdentifier = (collectionView.cellForItem(at: indexPath) as? LibraryViewCell)?.representedAssetIdentifier
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelected == currentlySelectedIdentifier
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                } else {
                    if let index = findIndexInSelectionPool(indexPath: indexPath) {
                        v.previewBox.select(indexInSelection: index, animated: true)
                    }
                }
            } else if isLimitExceeded == false {
                addToSelection(indexPath: indexPath)
                v.previewBox.inserted(at: selectedItems.count - 1)
            }
            collectionView.reloadItems(at: [indexPath])
            if let previouslySelectedIndexPath = findIndexPathInCurrentAlbum(identifier: previouslySelected) {
                collectionView.reloadItems(at: [previouslySelectedIndexPath])
            }
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: indexPath)
            v.previewBox.reload()
            // Force deseletion of previously selected cell.
            // In the case where the previous cell was loaded from iCloud, a new image was fetched
            // which triggered photoLibraryDidChange() and reloadItems() which breaks selection.
            //
            if let previouslySelectedIndexPath = findIndexPathInCurrentAlbum(identifier: previouslySelected),
               let previousCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as? LibraryViewCell {
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
