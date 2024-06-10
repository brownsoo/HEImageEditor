//
//  HEImageEditorUIConfiguration.swift
//  HEImageEditor
//
import UIKit

public class HEImageEditorUIConfiguration: NSObject {
    private static var single = HEImageEditorUIConfiguration()
    
    @objc public class func `default`() -> HEImageEditorUIConfiguration {
        return HEImageEditorUIConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        HEImageEditorUIConfiguration.single = HEImageEditorUIConfiguration()
    }
    
    /// HUD style. Defaults to dark.
    @objc public var hudStyle: HEProgressHUD.HUDStyle = .dark
    
    /// Adjust Slider Type
    @objc public var adjustSliderType: HEAdjustSliderType = .vertical
    
    // MARK: Language properties
    
    /// Language for framework.
    @objc public var languageType: HEImageEditorLanguageType = .system {
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
    
    /// Developers can customize images, but the name of the custom image resource must be consistent with the image name in the replaced bundle.
    /// - example: Developers need to replace the selected and unselected image resources, and the array that needs to be passed in is
    /// ["zl_btn_selected", "zl_btn_unselected"].
    @objc public var customImageNames: [String] = [] {
        didSet {
            HECustomImageDeploy.imageNames = customImageNames
        }
    }
    
    /// Developers can customize images, but the name of the custom image resource must be consistent with the image name in the replaced bundle.
    /// - example: Developers need to replace the selected and unselected image resources, and the array that needs to be passed in is
    /// ["zl_btn_selected": selectedImage, "zl_btn_unselected": unselectedImage].
    public var customImageForKey: [String: UIImage?] = [:] {
        didSet {
            customImageForKey.forEach { HECustomImageDeploy.imageForKey[$0.key] = $0.value }
        }
    }
    
    /// Developers can customize images, but the name of the custom image resource must be consistent with the image name in the replaced bundle.
    /// - example: Developers need to replace the selected and unselected image resources, and the array that needs to be passed in is
    /// ["zl_btn_selected": selectedImage, "zl_btn_unselected": unselectedImage].
    @objc public var customImageForKey_objc: [String: UIImage] = [:] {
        didSet {
            HECustomImageDeploy.imageForKey = customImageForKey_objc
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
    @objc public var ashbinNormalBgColor: UIColor = .he.rgba(40, 40, 40, 0.8)
    
    /// The tint background color of ashbin.
    @objc public var ashbinTintBgColor: UIColor = .he.rgba(241, 79, 79, 0.98)
    
    /// The normal color of the title below the various tools in the image editor.
    @objc public var toolTitleNormalColor: UIColor = .he.rgba(160, 160, 160)
    
    /// The tint color of the title below the various tools in the image editor.
    @objc public var toolTitleTintColor = UIColor.white

    /// The highlighted color of the tool icon.
    @objc public var toolIconHighlightedColor: UIColor? = .he.rgba(71, 120, 222)
}

// MARK: Image source deploy

enum HECustomImageDeploy {
    static var imageNames: [String] = []
    
    static var imageForKey: [String: UIImage] = [:]
}

@objc public enum HEAdjustSliderType: Int {
    case vertical
    case horizontal
}
