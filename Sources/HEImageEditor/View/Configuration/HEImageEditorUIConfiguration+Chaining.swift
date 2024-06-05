//
//  HEImageEditorUIConfiguration+Chaining.swift
//  HEImageEditor
//
//  Created by long on 2022/5/13.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public extension HEImageEditorUIConfiguration {
    @discardableResult
    func hudStyle(_ style: ZLProgressHUD.HUDStyle) -> HEImageEditorUIConfiguration {
        hudStyle = style
        return self
    }
    
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
    func customImageNames(_ names: [String]) -> HEImageEditorUIConfiguration {
        customImageNames = names
        return self
    }
    
    @discardableResult
    func customImageForKey(_ map: [String: UIImage?]) -> HEImageEditorUIConfiguration {
        customImageForKey = map
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
