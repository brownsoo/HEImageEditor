//
//  UIKit+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import Photos

extension UIApplication {
    @available(iOS 13.0, *)
    func findWindowScenes() -> [UIWindowScene] {
        return Self.shared.connectedScenes
            .sorted {
                $0.activationState.sortPriority < $1.activationState.sortPriority
            }
            .compactMap({ $0 as? UIWindowScene })
    }
    
    func findKeyWindow() -> UIWindow? {
        let scenes = findWindowScenes()
        if #available(iOS 15, *) {
            return scenes.first(where: { $0.keyWindow != nil })?.keyWindow ?? scenes.first?.keyWindow
        } else {
            return scenes.compactMap {
                $0.windows.first { $0.isKeyWindow }
            }
            .first
        }
    }
    
    func findKeyRootViewController() -> UIViewController? {
        return findKeyWindow()?.rootViewController
    }
}

@available(iOS 13.0, *)
private extension UIScene.ActivationState {
    var sortPriority: Int {
        switch self {
        case .foregroundActive: return 1
        case .foregroundInactive: return 2
        case .background: return 3
        case .unattached: return 4
        @unknown default: return 5
        }
    }
}

extension UIBarButtonItem {
    func setFont(font: UIFont?, forState state: UIControl.State) {
        guard font != nil else { return }
        self.setTitleTextAttributes([NSAttributedString.Key.font: font!], for: .normal)
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
