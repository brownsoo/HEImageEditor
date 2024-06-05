//
//  UIColor+HEImageEditor.swift
//  HEImageEditor
//

import UIKit

extension HEImageEditorWrapper where Base: UIColor {
    static var adjustSliderNormalColor: UIColor {
        HEImageEditorUIConfiguration.default().adjustSliderNormalColor
    }
    
    static var adjustSliderTintColor: UIColor {
        HEImageEditorUIConfiguration.default().adjustSliderTintColor
    }
    
    static var editDoneBtnBgColor: UIColor {
        HEImageEditorUIConfiguration.default().editDoneBtnBgColor
    }
    
    static var editDoneBtnTitleColor: UIColor {
        HEImageEditorUIConfiguration.default().editDoneBtnTitleColor
    }
    
    static var ashbinNormalBgColor: UIColor {
        HEImageEditorUIConfiguration.default().ashbinNormalBgColor
    }
    
    static var ashbinTintBgColor: UIColor {
        HEImageEditorUIConfiguration.default().ashbinTintBgColor
    }
    
    static var toolTitleNormalColor: UIColor {
        HEImageEditorUIConfiguration.default().toolTitleNormalColor
    }
    
    static var toolTitleTintColor: UIColor {
        HEImageEditorUIConfiguration.default().toolTitleTintColor
    }

    static var toolIconHighlightedColor: UIColor? {
        HEImageEditorUIConfiguration.default().toolIconHighlightedColor
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
