//
//  HEConfiguration+Chaining.swift
//  HEImageEditor
//

import UIKit

public extension HEConfiguration {
    @discardableResult
    func editImageTools(_ tools: [HEConfiguration.EditTool]) -> HEConfiguration {
        self.tools = tools
        return self
    }
    
    @discardableResult
    func drawColors(_ colors: [UIColor]) -> HEConfiguration {
        drawColors = colors
        return self
    }
    
    @discardableResult
    func defaultDrawColor(_ color: UIColor) -> HEConfiguration {
        defaultDrawColor = color
        return self
    }
    
    @discardableResult
    func clipRatios(_ ratios: [HEImageClipRatio]) -> HEConfiguration {
        clipRatios = ratios
        return self
    }
    
    @discardableResult
    func textStickerTextColors(_ colors: [UIColor]) -> HEConfiguration {
        textStickerTextColors = colors
        return self
    }
    
    @discardableResult
    func textStickerDefaultTextColor(_ color: UIColor) -> HEConfiguration {
        textStickerDefaultTextColor = color
        return self
    }
    
    @discardableResult
    func textStickerDefaultFont(_ font: UIFont?) -> HEConfiguration {
        textStickerDefaultFont = font
        return self
    }
    
    @discardableResult
    func textStickerCanLineBreak(_ enable: Bool) -> HEConfiguration {
        textStickerCanLineBreak = enable
        return self
    }
    
    @discardableResult
    func filters(_ filters: [HEFilter]) -> HEConfiguration {
        self.filters = filters
        return self
    }
    
    @discardableResult
    func imageStickerTray(_ view: (UIView & HEImageStickerTray)?) -> HEConfiguration {
        self.imageStickerTray = view
        return self
    }
    
    @discardableResult
    func adjustTools(_ tools: [HEConfiguration.AdjustTool]) -> HEConfiguration {
        adjustTools = tools
        return self
    }
    
    @available(iOS 10.0, *)
    @discardableResult
    func impactFeedbackWhenAdjustSliderValueIsZero(_ value: Bool) -> HEConfiguration {
        impactFeedbackWhenAdjustSliderValueIsZero = value
        return self
    }
    
    @available(iOS 10.0, *)
    @discardableResult
    func impactFeedbackStyle(_ style: HEConfiguration.FeedbackStyle) -> HEConfiguration {
        impactFeedbackStyle = style
        return self
    }
    
}
