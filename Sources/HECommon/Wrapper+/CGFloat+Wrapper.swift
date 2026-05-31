//
//  CGFloat+HEImageEditor.swift
//  HEImageEditor
//

import Foundation

public extension HEWrapper where Base == CGFloat {
    var toPi: CGFloat {
        return base / 180 * .pi
    }
}


public extension HEWrapper where Base == CGRect {
    
    /// 오직 90도 단위로 돌려서 0,0 위치로 붙임
    func rotate(rightAngle angle: Int) -> CGRect {
        let radians = CGFloat(angle) / 180 * CGFloat.pi
        var newFrame = CGRect(x: base.minX * cos(radians) + base.minY * sin(radians) * -1,
                              y: base.minX * sin(radians) + base.minY * cos(radians),
                              width: base.width,
                              height: base.height)
        
        let a = ((angle % 360) - 360) % 360
        if a == -90 {
            newFrame = CGRect(origin: CGPoint(x: newFrame.minY * -1, y: newFrame.minX),
                              size: CGSize(width: base.height, height: base.width))
        } else if a == -180 {
            newFrame.origin = CGPoint(x: newFrame.minX * -1, y: newFrame.minY * -1)
        } else if a == -270 {
            newFrame = CGRect(origin: CGPoint(x: newFrame.minY, y: newFrame.minX * -1),
                              size: CGSize(width: base.height, height: base.width))
        }
        
        return newFrame
    }
}
