//
//  HEClipStatus.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/20/24.
//

import Foundation

public struct HEClipStatus {
    /// 이미지 내 영역
    var editRect: CGRect
    var angle: CGFloat = 0
    var ratio: HEImageClipRatio?
    
    public init(
        editRect: CGRect,
        angle: CGFloat = 0,
        ratio: HEImageClipRatio? = nil
    ) {
        self.editRect = editRect
        self.angle = angle
        self.ratio = ratio
    }
}
