//
//  HEImageEditorConfiguration.swift
//  HEImageEditor
//

import UIKit

public class HEImageEditorConfiguration: NSObject {
    private static var single = HEImageEditorConfiguration()
    
    private static let defaultColors: [UIColor] = [
        .white,
        .black,
        .he.rgba(249, 80, 81),
        .he.rgba(248, 156, 59),
        .he.rgba(255, 195, 0),
        .he.rgba(145, 211, 0),
        .he.rgba(0, 193, 94),
        .he.rgba(16, 173, 254),
        .he.rgba(16, 132, 236),
        .he.rgba(99, 103, 240),
        .he.rgba(127, 127, 127)
    ]
    
    @objc public class func `default`() -> HEImageEditorConfiguration {
        return HEImageEditorConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        HEImageEditorConfiguration.single = HEImageEditorConfiguration()
    }
    
    private var _tools: [HEImageEditorConfiguration.EditTool] = [.draw, .clip, .imageSticker, .textSticker, .mosaic, .filter, .adjust]
    
    /// Edit image tools. (Default order is draw, clip, imageSticker, textSticker, mosaic, filtter)
    /// - warning: If you want to use the image sticker feature, you must provide a view that implements HEImageStickerContainerDelegate.
    public var tools: [HEImageEditorConfiguration.EditTool] {
        get {
            if _tools.isEmpty {
                return [.draw, .clip, .imageSticker, .textSticker, .mosaic, .filter, .adjust]
            } else {
                return _tools
            }
        }
        set {
            _tools = newValue
        }
    }
    
    private var _drawColors = HEImageEditorConfiguration.defaultColors
    /// Draw colors for image editor.
    @objc public var drawColors: [UIColor] {
        get {
            if _drawColors.isEmpty {
                return HEImageEditorConfiguration.defaultColors
            } else {
                return _drawColors
            }
        }
        set {
            _drawColors = newValue
        }
    }
    
    /// The default draw color. If this color not in editImageDrawColors, will pick the first color in editImageDrawColors as the default.
    @objc public var defaultDrawColor: UIColor = .he.rgba(249, 80, 81)
    
    private var pri_clipRatios: [HEImageClipRatio] = [.custom]
    /// Edit ratios for image editor.
    @objc public var clipRatios: [HEImageClipRatio] {
        get {
            if pri_clipRatios.isEmpty {
                return [.custom]
            } else {
                return pri_clipRatios
            }
        }
        set {
            pri_clipRatios = newValue
        }
    }
    
    private var _textStickerTextColors = HEImageEditorConfiguration.defaultColors
    /// Text sticker colors for image editor.
    @objc public var textStickerTextColors: [UIColor] {
        get {
            if _textStickerTextColors.isEmpty {
                return HEImageEditorConfiguration.defaultColors
            } else {
                return _textStickerTextColors
            }
        }
        set {
            _textStickerTextColors = newValue
        }
    }
    
    /// The default text sticker color. If this color not in textStickerTextColors, will pick the first color in textStickerTextColors as the default.
    @objc public var textStickerDefaultTextColor = UIColor.white
    
    /// The default font of text sticker.
    /// - Note: This property is ignored when using fontChooserContainerView.
    @objc public var textStickerDefaultFont: UIFont?
    
    /// Whether text sticker allows line break.
    @objc public var textStickerCanLineBreak = false
    
    private var _filters: [HEFilter] = HEFilter.all
    /// Filters for image editor.
    @objc public var filters: [HEFilter] {
        get {
            if _filters.isEmpty {
                return HEFilter.all
            } else {
                return _filters
            }
        }
        set {
            _filters = newValue
        }
    }
    
    @objc public var imageStickerContainerView: (UIView & HEImageStickerContainerDelegate)?

    @objc public var fontChooserContainerView: (UIView & HETextFontChooserDelegate)?

    private var _adjustTools: [HEImageEditorConfiguration.AdjustTool] = [.brightness, .contrast, .saturation]
    /// Adjust image tools. (Default order is brightness, contrast, saturation)
    /// Valid when the tools contain EditTool.adjust
    /// Because Objective-C Array can't contain Enum styles, so this property is invalid in Objective-C.
    public var adjustTools: [HEImageEditorConfiguration.AdjustTool] {
        get {
            if _adjustTools.isEmpty {
                return [.brightness, .contrast, .saturation]
            } else {
                return _adjustTools
            }
        }
        set {
            _adjustTools = newValue
        }
    }
    
    private var _impactFeedbackWhenAdjustSliderValueIsZero = true
    /// Give an impact feedback when the adjust slider value is zero. Defaults to true.
    @available(iOS 10.0, *)
    @objc public var impactFeedbackWhenAdjustSliderValueIsZero: Bool {
        get {
            return _impactFeedbackWhenAdjustSliderValueIsZero
        }
        set {
            _impactFeedbackWhenAdjustSliderValueIsZero = newValue
        }
    }
    
    private var _impactFeedbackStyle: HEImageEditorConfiguration.FeedbackStyle = .medium
    /// Impact feedback style. Defaults to .medium
    @available(iOS 10.0, *)
    @objc public var impactFeedbackStyle: HEImageEditorConfiguration.FeedbackStyle {
        get {
            return _impactFeedbackStyle
        }
        set {
            _impactFeedbackStyle = .medium
        }
    }
    
    /// If image edit tools only has clip and this property is true. When you click edit, the cropping interface (i.e. ZLClipImageViewController) will be displayed. Defaults to false
    @objc public var showClipDirectlyIfOnlyHasClipTool = false
}

public extension HEImageEditorConfiguration {
    @objc enum EditTool: Int {
        case draw
        case clip
        case imageSticker
        case textSticker
        case mosaic
        case filter
        case adjust
    }
    
    @objc enum AdjustTool: Int {
        case brightness
        case contrast
        case saturation
        
        var key: String {
            switch self {
            case .brightness:
                return kCIInputBrightnessKey
            case .contrast:
                return kCIInputContrastKey
            case .saturation:
                return kCIInputSaturationKey
            }
        }
        
        func filterValue(_ value: Float) -> Float {
            switch self {
            case .brightness:
                // 밝기 범위 -1~1, 기본값 0, 3으로 나누기, -0.33~0.33
                return value / 3
            case .contrast:
                // 대비 범위 0~4, 기본값 1, 여기에서 계산하려면 0.5~2.5를 사용합니다.
                let v: Float
                if value < 0 {
                    v = 1 + value * (1 / 2)
                } else {
                    v = 1 + value * (3 / 2)
                }
                return v
            case .saturation:
                // 채도 범위 0~2, 기본값 1
                return value + 1
            }
        }
    }
    
    @objc enum FeedbackStyle: Int {
        case light
        case medium
        case heavy
        
        @available(iOS 10.0, *)
        var uiFeedback: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:
                return .light
            case .medium:
                return .medium
            case .heavy:
                return .heavy
            }
        }
    }
}

// MARK: Clip ratio.

public class HEImageClipRatio: NSObject {
    @objc public var title: String
    
    @objc public let whRatio: CGFloat
    
    @objc public let isCircle: Bool
    
    @objc public init(title: String, whRatio: CGFloat, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.isCircle = isCircle
        super.init()
    }
}

extension HEImageClipRatio {
    static func == (lhs: HEImageClipRatio, rhs: HEImageClipRatio) -> Bool {
        return lhs.whRatio == rhs.whRatio
    }
}

public extension HEImageClipRatio {
    @objc static let all: [HEImageClipRatio] = [.custom, .circle, .wh1x1, .wh3x4, .wh4x3, .wh2x3, .wh3x2, .wh9x16, .wh16x9]
    
    @objc static let custom = HEImageClipRatio(title: "custom", whRatio: 0)
    
    @objc static let circle = HEImageClipRatio(title: "circle", whRatio: 1, isCircle: true)
    
    @objc static let wh1x1 = HEImageClipRatio(title: "1 : 1", whRatio: 1)
    
    @objc static let wh3x4 = HEImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0)
    
    @objc static let wh4x3 = HEImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0)
    
    @objc static let wh2x3 = HEImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0)
    
    @objc static let wh3x2 = HEImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0)
    
    @objc static let wh9x16 = HEImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0)
    
    @objc static let wh16x9 = HEImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0)
}

/// Provide an image sticker container view that conform to this protocol must be a subclass of UIView
@objc public protocol HEImageStickerContainerDelegate {
    @objc var selectImageBlock: ((UIImage) -> Void)? { get set }
    
    @objc var hideBlock: (() -> Void)? { get set }
    
    @objc func show(in view: UIView)
}

/// Provide an text font choose view that conform to this protocol must be a subclass of UIView
@objc public protocol HETextFontChooserDelegate {
    @objc var selectFontBlock: ((UIFont) -> Void)? { get set }

    @objc var hideBlock: (() -> Void)? { get set }

    @objc func show(in view: UIView)
}
