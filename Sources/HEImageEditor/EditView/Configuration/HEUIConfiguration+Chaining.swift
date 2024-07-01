//
//  HEUIConfiguration+Chaining.swift
//  HEImageEditor
//

import UIKit

public extension HEUIConfiguration {
        
    @discardableResult
    func adjustSliderType(_ type: HEAdjustSliderType) -> HEUIConfiguration {
        adjustSliderType = type
        return self
    }
    
    @discardableResult
    func languageType(_ type: HELanguageType) -> HEUIConfiguration {
        languageType = type
        return self
    }
    
    @discardableResult
    func customLanguageConfig(_ config: [HELocalLanguageKey: String]) -> HEUIConfiguration {
        customLanguageConfig = config
        return self
    }
    
    @discardableResult
    func adjustSliderNormalColor(_ color: UIColor) -> HEUIConfiguration {
        adjustSliderNormalColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderTintColor(_ color: UIColor) -> HEUIConfiguration {
        adjustSliderTintColor = color
        return self
    }
    
    @discardableResult
    func editDoneBtnBgColor(_ color: UIColor) -> HEUIConfiguration {
        editDoneBtnBgColor = color
        return self
    }
    
    @discardableResult
    func editDoneBtnTitleColor(_ color: UIColor) -> HEUIConfiguration {
        editDoneBtnTitleColor = color
        return self
    }
    
    @discardableResult
    func ashbinNormalBgColor(_ color: UIColor) -> HEUIConfiguration {
        ashbinNormalBgColor = color
        return self
    }
    
    @discardableResult
    func ashbinTintBgColor(_ color: UIColor) -> HEUIConfiguration {
        ashbinTintBgColor = color
        return self
    }
    
    @discardableResult
    func toolTitleNormalColor(_ color: UIColor) -> HEUIConfiguration {
        toolTitleNormalColor = color
        return self
    }
    
    @discardableResult
    func toolTitleTintColor(_ color: UIColor) -> HEUIConfiguration {
        toolTitleTintColor = color
        return self
    }

    @discardableResult
    func toolIconHighlightedColor(_ color: UIColor) -> HEUIConfiguration {
        toolIconHighlightedColor = color
        return self
    }
}
