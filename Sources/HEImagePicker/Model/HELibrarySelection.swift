//
//  HELibrarySelection.swift
//  HEImagePicker
//
//  Created by hyonsoo on 7/2/24.
//

import Foundation
import UIKit

/// 라이브러리 선택 아이템 모델
///
/// - 크롭 위치, 영역
public struct HELibrarySelection {
    let assetIdentifier: String
    var cropRect: CGRect?
    var scrollViewContentOffset: CGPoint?
    var scrollViewZoomScale: CGFloat?
    
    init(assetIdentifier: String,
         cropRect: CGRect? = nil,
         scrollViewContentOffset: CGPoint? = nil,
         scrollViewZoomScale: CGFloat? = nil) {
        self.assetIdentifier = assetIdentifier
        self.cropRect = cropRect
        self.scrollViewContentOffset = scrollViewContentOffset
        self.scrollViewZoomScale = scrollViewZoomScale
    }
}
