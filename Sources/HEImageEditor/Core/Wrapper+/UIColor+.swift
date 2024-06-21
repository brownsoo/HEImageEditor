//
//  UIColor+HEImageEditor.swift
//  HEImageEditor
//

import UIKit

extension HEImageEditorWrapper where Base: UIColor {
    static var adjustSliderNormalColor: UIColor {
        HEUIConfiguration.default().adjustSliderNormalColor
    }
    
    static var adjustSliderTintColor: UIColor {
        HEUIConfiguration.default().adjustSliderTintColor
    }
    
    static var editDoneBtnBgColor: UIColor {
        HEUIConfiguration.default().editDoneBtnBgColor
    }
    
    static var editDoneBtnTitleColor: UIColor {
        HEUIConfiguration.default().editDoneBtnTitleColor
    }
    
    static var trashbinNormalBgColor: UIColor {
        HEUIConfiguration.default().ashbinNormalBgColor
    }
    
    static var trashbinTintBgColor: UIColor {
        HEUIConfiguration.default().ashbinTintBgColor
    }
    
    static var toolTitleNormalColor: UIColor {
        HEUIConfiguration.default().toolTitleNormalColor
    }
    
    static var toolTitleTintColor: UIColor {
        HEUIConfiguration.default().toolTitleTintColor
    }

    static var toolIconHighlightedColor: UIColor? {
        HEUIConfiguration.default().toolIconHighlightedColor
    }
}

extension HEImageEditorWrapper where Base: UIColor {
    /// - Parameters:
    ///   - r: 0~255
    ///   - g: 0~255
    ///   - b: 0~255
    ///   - a: 0~1
    static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
}
