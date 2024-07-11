//
//  CGRect+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//


import UIKit

infix operator &/

// With that you can devide to zero
extension CGFloat {
    static func &/ (lhs: CGFloat, rhs: CGFloat) -> CGFloat {
        if rhs == 0 {
            return 0
        }
        return lhs/rhs
    }
}


extension CGRect {
    
    func differenceWith(rect: CGRect,
                        removedHandler: (CGRect) -> Void,
                        addedHandler: (CGRect) -> Void) {
        if rect.intersects(self) {
            let oldMaxY = self.maxY
            let oldMinY = self.minY
            let newMaxY = rect.maxY
            let newMinY = rect.minY
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: rect.origin.x,
                                       y: oldMaxY,
                                       width: rect.size.width,
                                       height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: rect.origin.x,
                                       y: newMinY,
                                       width: rect.size.width,
                                       height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: rect.origin.x,
                                          y: newMaxY,
                                          width: rect.size.width,
                                          height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: rect.origin.x,
                                          y: oldMinY,
                                          width: rect.size.width,
                                          height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(rect)
            removedHandler(self)
        }
    }
}
