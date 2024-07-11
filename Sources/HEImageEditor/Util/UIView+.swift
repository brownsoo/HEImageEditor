//
//  UIView+HEImageEditor.swift
//  HEImageEditor
//

import UIKit
import HECommon

extension HEWrapper where Base: UIView {
    var top: CGFloat {
        base.frame.minY
    }
    
    var bottom: CGFloat {
        base.frame.maxY
    }
    
    var left: CGFloat {
        base.frame.minX
    }
    
    var right: CGFloat {
        base.frame.maxX
    }
    
    var width: CGFloat {
        base.frame.width
    }
    
    var height: CGFloat {
        base.frame.height
    }
}
