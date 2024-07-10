//
//  UIKit+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import Photos

extension UIBarButtonItem {
    func setFont(font: UIFont?, forState state: UIControl.State) {
        guard font != nil else { return }
        self.setTitleTextAttributes([NSAttributedString.Key.font: font!], for: state)
    }
}


extension UICollectionView {
    func aapl_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
}

extension PHFetchResult where ObjectType == PHAsset {
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
            let asset = self[indexPath.item]
            assets.append(asset)
        }
        return assets
    }
}


internal extension IndexSet {
    func aapl_indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(count)
        (self as NSIndexSet).enumerate({idx, _ in
            indexPaths.append(IndexPath(item: idx, section: section))
        })
        return indexPaths
    }
}

extension UIViewController {
    @discardableResult
    func showAlert(_ text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return self.showAlert(title: nil, text: text, confirmAction: confirmAction)
    }
    
    @discardableResult
    func showAlert(title: String? = nil, text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        DispatchQueue.main.async {
            let okayAction = UIAlertAction(title: PickerConfig.wordings.confirm, style: .default, handler: confirmAction)
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
        return alert
    }
}
