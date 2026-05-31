//
//  HEImageEditorUIConfiguration.swift
//  HEImageEditor
//
import UIKit
import HECommon

public class HEImageEditorUIConfiguration: NSObject {
    private static var single = HEImageEditorUIConfiguration()
    
    @objc public class func `default`() -> HEImageEditorUIConfiguration {
        return HEImageEditorUIConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        HEImageEditorUIConfiguration.single = HEImageEditorUIConfiguration()
    }
        
    /// Adjust Slider Type
    @objc public var adjustSliderType: HEAdjustSliderType = .vertical
    
    // MARK: Color properties
    
    /// The normal color of adjust slider.
    @objc public var adjustSliderNormalColor = UIColor.white
    
    /// The tint color of adjust slider.
    @objc public var adjustSliderTintColor: UIColor = .he.rgba(7, 213, 101)
    
    /// The background color of edit done button.
    @objc public var editDoneBtnBgColor: UIColor = .he.rgba(7, 213, 101)
    
    /// The title color of edit done button.
    @objc public var editDoneBtnTitleColor = UIColor.white
    
    /// The normal background color of ashbin.
    @objc public var ashbinNormalBgColor: UIColor = .he.rgba(51, 51, 51, 0.2)
    
    /// The tint background color of ashbin.
    @objc public var ashbinTintBgColor: UIColor = .he.rgba(248, 9, 9, 0.62)
    
    /// The normal color of the title below the various tools in the image editor.
    @objc public var toolTitleNormalColor: UIColor = .he.rgba(160, 160, 160)
    
    /// The tint color of the title below the various tools in the image editor.
    @objc public var toolTitleTintColor = UIColor.white

    /// The highlighted color of the tool icon.
    @objc public var toolIconHighlightedColor: UIColor? = .he.rgba(71, 120, 222)
}

@objc public enum HEAdjustSliderType: Int {
    case vertical
    case horizontal
}
