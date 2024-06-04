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

public struct ZLLocalLanguageKey: Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Cancel (取消)
    public static let cancel = ZLLocalLanguageKey(rawValue: "cancel")
    
    /// Done (确定)
    public static let done = ZLLocalLanguageKey(rawValue: "done")
    
    /// Done (完成)
    public static let editFinish = ZLLocalLanguageKey(rawValue: "editFinish")
    
    /// Undo (还原)
    public static let revert = ZLLocalLanguageKey(rawValue: "revert")
    
    /// Brightness (亮度)
    public static let brightness = ZLLocalLanguageKey(rawValue: "brightness")
    
    /// Contrast (对比度)
    public static let contrast = ZLLocalLanguageKey(rawValue: "contrast")
    
    /// Saturation (饱和度)
    public static let saturation = ZLLocalLanguageKey(rawValue: "saturation")
    
    /// Drag here to remove (拖到此处删除)
    public static let textStickerRemoveTips = ZLLocalLanguageKey(rawValue: "textStickerRemoveTips")
    
    /// Processing (正在处理)
    public static let hudProcessing = ZLLocalLanguageKey(rawValue: "hudProcessing")
}

func localLanguageTextValue(_ key: ZLLocalLanguageKey) -> String {
    if let value = HEImageEditorUIConfiguration.default().customLanguageConfig[key] {
        return value
    }
    
    return Bundle.zlLocalizedString(key.rawValue)
}
