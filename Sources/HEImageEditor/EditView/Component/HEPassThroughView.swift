//
//  HEPassThroughView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/14/24.
//

import UIKit

open class HEPassThroughView: UIView {
    /// 스티커 대상 선택 제공자
    public var findResponderSticker: ((CGPoint) -> UIView?)?
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else {
            return super.hitTest(point, with: event)
        }
        
        for view in subviews.reversed() {
            let point = convert(point, to: view)
            if !view.isHidden,
               view.alpha != 0,
               view.bounds.contains(point) {
                return view.hitTest(point, with: event)
            }
        }
        
        if let sticker = findResponderSticker?(convert(point, to: superview)) {
            return sticker.hitTest(point, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
}
