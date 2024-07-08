//
//  HEImageEditorUIConfiguration.swift
//  HEImageEditor
//
import UIKit
import HECommon

public class HEUIConfiguration: NSObject {
    private static var single = HEUIConfiguration()
    
    @objc public class func `default`() -> HEUIConfiguration {
        return HEUIConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        HEUIConfiguration.single = HEUIConfiguration()
    }
        
    /// Adjust Slider Type
    @objc public var adjustSliderType: HEAdjustSliderType = .vertical
    
    // MARK: Language properties
    
    /// Language for framework.
    @objc public var languageType: HELanguageType = .system {
        didSet {
            Bundle.resetLanguage()
        }
    }
    
    /// Developers can customize languages.
    /// - example: If you needs to replace
    /// key: .hudProcessing, value: "loading, waiting please" language,
    /// The dictionary that needs to be passed in is [.hudProcessing: "text to be replaced"].
    /// - warning: Please pay attention to the placeholders contained in languages when changing, such as %ld, %@.
    public var customLanguageConfig: [HELocalLanguageKey: String] = [:]
    
    /// Developers can customize languages (This property is only for objc).
    /// - example: If you needs to replace
    /// key: @"loading", value: @"loading, waiting please" language,
    /// The dictionary that needs to be passed in is @[@"hudProcessing": @"text to be replaced"].
    /// - warning: Please pay attention to the placeholders contained in languages when changing, such as %ld, %@.
    @objc public var customLanguageConfig_objc: [String: String] = [:] {
        didSet {
            var swiftParams: [HELocalLanguageKey: String] = [:]
            customLanguageConfig_objc.forEach { key, value in
                swiftParams[HELocalLanguageKey(rawValue: key)] = value
            }
            customLanguageConfig = swiftParams
        }
    }
    
    
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
    @objc public var ashbinNormalBgColor: UIColor = .he.rgba(248, 9, 9, 0.62)
    
    /// The tint background color of ashbin.
    @objc public var ashbinTintBgColor: UIColor = .he.rgba(248, 9, 9, 0.88)
    
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
