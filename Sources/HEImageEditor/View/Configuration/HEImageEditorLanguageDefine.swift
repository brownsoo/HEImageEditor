//
//  HEImageEditorLanguageDefine.swift
//  HEImageEditor
//
import Foundation

@objc public enum HEImageEditorLanguageType: Int {
    case system
    case english
    case korean
    
    var key: String {
        var key = "en"
        
        switch HEImageEditorUIConfiguration.default().languageType {
        case .system:
            key = Locale.preferredLanguages.first ?? "en"
            
            if key.hasPrefix("ko") {
                key = "ko"
            } else {
                key = "en"
            }
            
        case .english:
            key = "en"
        case .korean:
            key = "ko"
        }
        return key   
    }
}

public struct HELocalLanguageKey: Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let customRatio = HELocalLanguageKey(rawValue: "custom ratio")
    public static let original = HELocalLanguageKey(rawValue: "original")
    public static let rotate = HELocalLanguageKey(rawValue: "rotate")
    
    /// Cancel
    public static let cancel = HELocalLanguageKey(rawValue: "cancel")
    
    /// Done
    public static let done = HELocalLanguageKey(rawValue: "done")
    
    /// Done
    public static let editFinish = HELocalLanguageKey(rawValue: "editFinish")
    
    /// Undo
    public static let revert = HELocalLanguageKey(rawValue: "revert")
    
    /// Brightness
    public static let brightness = HELocalLanguageKey(rawValue: "brightness")
    
    /// Contrast
    public static let contrast = HELocalLanguageKey(rawValue: "contrast")
    
    /// Saturation
    public static let saturation = HELocalLanguageKey(rawValue: "saturation")
    
    /// Drag here to remove
    public static let textStickerRemoveTips = HELocalLanguageKey(rawValue: "textStickerRemoveTips")
    
    /// Processing
    public static let hudProcessing = HELocalLanguageKey(rawValue: "hudProcessing")
}

func localLanguageTextValue(_ key: HELocalLanguageKey) -> String {
    if let value = HEImageEditorUIConfiguration.default().customLanguageConfig[key] {
        return value
    }
    
    return Bundle.heLocalizedString(key.rawValue)
}
