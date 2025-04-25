//
//  Cell+HEImageEditor.swift
//  HEImageEditor
//


import UIKit
import HECommon

extension HEWrapper where Base: UICollectionViewCell {
    static var identifier: String {
        NSStringFromClass(Base.self)
    }
    
    static func register(_ collectionView: UICollectionView) {
        collectionView.register(Base.self, forCellWithReuseIdentifier: identifier)
    }
}
