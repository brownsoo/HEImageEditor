//
//  HEImageEditorUIConfiguration+Chaining.swift
//  HEImageEditor
//

import UIKit

public extension HEImageEditorUIConfiguration {
        
    @discardableResult
    func adjustSliderType(_ type: HEAdjustSliderType) -> HEImageEditorUIConfiguration {
        adjustSliderType = type
        return self
    }
    
    @discardableResult
    func languageType(_ type: HEImageEditorLanguageType) -> HEImageEditorUIConfiguration {
        languageType = type
        return self
    }
    
    @discardableResult
    func customLanguageConfig(_ config: [HELocalLanguageKey: String]) -> HEImageEditorUIConfiguration {
        customLanguageConfig = config
        return self
    }
    
    @discardableResult
    func adjustSliderNormalColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        adjustSliderNormalColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderTintColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        adjustSliderTintColor = color
        return self
    }
    
    @discardableResult
    func editDoneBtnBgColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        editDoneBtnBgColor = color
        return self
    }
    
    @discardableResult
    func editDoneBtnTitleColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        editDoneBtnTitleColor = color
        return self
    }
    
    @discardableResult
    func ashbinNormalBgColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        ashbinNormalBgColor = color
        return self
    }
    
    @discardableResult
    func ashbinTintBgColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        ashbinTintBgColor = color
        return self
    }
    
    @discardableResult
    func toolTitleNormalColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        toolTitleNormalColor = color
        return self
    }
    
    @discardableResult
    func toolTitleTintColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        toolTitleTintColor = color
        return self
    }

    @discardableResult
    func toolIconHighlightedColor(_ color: UIColor) -> HEImageEditorUIConfiguration {
        toolIconHighlightedColor = color
        return self
    }
}
