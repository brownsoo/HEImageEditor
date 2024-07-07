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
    
    func startMultipleSelection(at indexPath: IndexPath) {
        currentlySelectedIndex = indexPath.row
        toggleMultipleSelection()
        
        // Update preview.
        changeAsset(mediaManager.getAsset(at: indexPath.row))

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
        if let positionIndex = selectedItems.firstIndex(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
        }) {
            selectedItems.remove(at: positionIndex)

            // Refresh the numbers
            let selectedIndexPaths = selectedItems.map { IndexPath(row: $0.index, section: 0) }
            v.albumCollectionView.reloadItems(at: selectedIndexPaths)
            
            // Replace the current selected image with the previously selected one
            if let previouslySelectedIndexPath = selectedIndexPaths.last {
                v.albumCollectionView.deselectItem(at: indexPath, animated: false)
                v.albumCollectionView.selectItem(at: previouslySelectedIndexPath, animated: false, scrollPosition: [])
                currentlySelectedIndex = previouslySelectedIndexPath.row
                changeAsset(mediaManager.getAsset(at: previouslySelectedIndexPath.row))
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
        guard let asset = mediaManager.getAsset(at: indexPath.item) else {
            print("No asset to add to selection.")
            return
        }

        let newSelection = HELibrarySelection(index: indexPath.row, assetIdentifier: asset.localIdentifier)
        selectedItems.append(newSelection)
        checkLimit()
    }
    
    func isInSelectionPool(indexPath: IndexPath) -> Bool {
        return selectedItems.contains(where: {
            $0.assetIdentifier == mediaManager.getAsset(at: indexPath.row)?.localIdentifier
        })
    }
    
    /// Checks if there can be selected more items. If no - present warning.
    func checkLimit() {
        //v.maxNumberWarningView.isHidden = !isLimitExceeded || isMultipleSelectionEnabled == false
        trace(isLimitExceeded || isMultipleSelectionEnabled == false)
        v.countLabel?.text = String(selectedItems.count)
    }
}

extension HELibraryViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult?.count ?? 0
    }
}

extension HELibraryViewController: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryViewCell.reuseIdentifier, for: indexPath) as? LibraryViewCell else {
            fatalError("unexpected cell in collection view")
        }
        
        var identifier: String
        var mediaType: PHAssetMediaType
        var phAsset: PHAsset?
        
        // Replacing thumbnail from external source
        if let media = delegate?.libraryView(self, replacingItemAt: indexPath) {
            switch media {
            case .photo(let photo):
                identifier = photo.identifier
                mediaType = .image
                phAsset = photo.asset
            case .video(let video):
                identifier = video.identifier
                mediaType = .video
                phAsset = video.asset
            }
            
          // Original thumbnail from photo album
        } else if let asset = mediaManager.getAsset(at: indexPath.item) {
            identifier = asset.localIdentifier
            mediaType = asset.mediaType
            mediaManager.phImageManager?.requestImage(for: asset,
                                                      targetSize: v.cellSize(),
                                                      contentMode: .aspectFill,
                                                      options: nil) { image, _ in
                // The cell may have been recycled when the time this gets called
                // set image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                    cell.imageView.image = image
                }
            }
        } else {
            return cell
        }

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
        cell.isSelected = currentlySelectedIndex == indexPath.row
        
        // Set correct selection number
        if let index = selectedItems.firstIndex(where: { $0.assetIdentifier == identifier }) {
            let currentSelection = selectedItems[index]
            if currentSelection.index < 0 {
                selectedItems[index] = HELibrarySelection(index: indexPath.row,
                                                      cropRect: currentSelection.cropRect,
                                                      scrollViewContentOffset: currentSelection.scrollViewContentOffset,
                                                      scrollViewZoomScale: currentSelection.scrollViewZoomScale,
                                                      assetIdentifier: currentSelection.assetIdentifier)
            }
            cell.multipleSelectionIndicator.set(number: index + 1) // start at 1, not 0
        } else {
            cell.multipleSelectionIndicator.set(number: nil)
        }

        if let caption = delegate?.libraryView(self, captionAt: indexPath) {
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
        let previouslySelectedIndexPath = IndexPath(row: currentlySelectedIndex, section: 0)
        currentlySelectedIndex = indexPath.row

        changeAsset(mediaManager.getAsset(at: indexPath.row))
        panGestureHelper.resetToOriginalState()
        
        // Only scroll cell to top if preview is hidden.
        if !panGestureHelper.isImageShown {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        v.refreshImageCurtainAlpha()
            
        if isMultipleSelectionEnabled {
            let cellIsInTheSelectionPool = isInSelectionPool(indexPath: indexPath)
            let cellIsCurrentlySelected = previouslySelectedIndexPath.row == currentlySelectedIndex
            if cellIsInTheSelectionPool {
                if cellIsCurrentlySelected {
                    deselect(indexPath: indexPath)
                }
            } else if isLimitExceeded == false {
                addToSelection(indexPath: indexPath)
            }
            collectionView.reloadItems(at: [indexPath])
            collectionView.reloadItems(at: [previouslySelectedIndexPath])
        } else {
            selectedItems.removeAll()
            addToSelection(indexPath: indexPath)
            
            // Force deseletion of previously selected cell.
            // In the case where the previous cell was loaded from iCloud, a new image was fetched
            // which triggered photoLibraryDidChange() and reloadItems() which breaks selection.
            //
            if let previousCell = collectionView.cellForItem(at: previouslySelectedIndexPath) as? LibraryViewCell {
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
