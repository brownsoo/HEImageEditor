//
//  HEImageEditorConfiguration+Chaining.swift
//  HEImageEditor
//

import UIKit

public extension HEImageEditorConfiguration {
    @discardableResult
    func editImageTools(_ tools: [HEImageEditorConfiguration.EditTool]) -> HEImageEditorConfiguration {
        self.tools = tools
        return self
    }
    
    @discardableResult
    func drawColors(_ colors: [UIColor]) -> HEImageEditorConfiguration {
        drawColors = colors
        return self
    }
    
    @discardableResult
    func defaultDrawColor(_ color: UIColor) -> HEImageEditorConfiguration {
        defaultDrawColor = color
        return self
    }
    
    @discardableResult
    func clipRatios(_ ratios: [HEImageClipRatio]) -> HEImageEditorConfiguration {
        clipRatios = ratios
        return self
    }
    
    @discardableResult
    func textStickerTextColors(_ colors: [UIColor]) -> HEImageEditorConfiguration {
        textStickerTextColors = colors
        return self
    }
    
    @discardableResult
    func textStickerDefaultTextColor(_ color: UIColor) -> HEImageEditorConfiguration {
        textStickerDefaultTextColor = color
        return self
    }
    
    @discardableResult
    func textStickerDefaultFont(_ font: UIFont?) -> HEImageEditorConfiguration {
        textStickerDefaultFont = font
        return self
    }
    
    @discardableResult
    func textStickerCanLineBreak(_ enable: Bool) -> HEImageEditorConfiguration {
        textStickerCanLineBreak = enable
        return self
    }
    
    @discardableResult
    func filters(_ filters: [HEFilter]) -> HEImageEditorConfiguration {
        self.filters = filters
        return self
    }
    
    @discardableResult
    func imageStickerTray(_ view: (UIView & HEImageStickerTray)?) -> HEImageEditorConfiguration {
        self.imageStickerTray = view
        return self
    }
    
    @discardableResult
    func adjustTools(_ tools: [HEImageEditorConfiguration.AdjustTool]) -> HEImageEditorConfiguration {
        adjustTools = tools
        return self
    }
    
    @available(iOS 10.0, *)
    @discardableResult
    func impactFeedbackWhenAdjustSliderValueIsZero(_ value: Bool) -> HEImageEditorConfiguration {
        impactFeedbackWhenAdjustSliderValueIsZero = value
        return self
    }
    
    @available(iOS 10.0, *)
    @discardableResult
    func impactFeedbackStyle(_ style: HEImageEditorConfiguration.FeedbackStyle) -> HEImageEditorConfiguration {
        impactFeedbackStyle = style
        return self
    }
    
}
