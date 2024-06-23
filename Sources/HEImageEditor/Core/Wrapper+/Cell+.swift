//
//  Cell+HEImageEditor.swift
//  HEImageEditor
//


import UIKit

extension HEWrapper where Base: UICollectionViewCell {
    static var identifier: String {
        NSStringFromClass(Base.self)
    }
    
    static func register(_ collectionView: UICollectionView) {
        collectionView.register(Base.self, forCellWithReuseIdentifier: identifier)
    }
}
