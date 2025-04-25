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
    /// rotation in degree 360
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
    /// rotation in radians
    var rotation: CGFloat {
        angle / 180 * CGFloat.pi
    }
    
    func clone() -> HEClipStatus {
        HEClipStatus(editRect: self.editRect, angle: self.angle, ratio: self.ratio?.clone())
    }
}
