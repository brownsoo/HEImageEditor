//
//  HEImageEditorConfiguration.swift
//  HEImageEditor
//

import UIKit

var EditorConfig: HEImageEditorConfiguration {
    HEImageEditorConfiguration.default()
}

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
    
    @objc public var textStickerDefaultTextColor = UIColor.white
    private static let defaultTextColors: [UIColor] = [
        .white,
        .black,
        .he.rgba(255, 0, 0),
        .he.rgba(254, 107, 2),
        .he.rgba(254, 184, 0),
        .he.rgba(16, 198, 35),
        .he.rgba(6, 106, 254),
        .he.rgba(190, 0, 255)
    ]
    
    @objc public var textStickerDefaultFillColor = UIColor.clear
    private static let defaultTextFillColors: [UIColor] = [
        .clear,
        .he.rgba(104, 204, 254),
        .he.rgba(254, 124, 62),
        .he.rgba(524, 184, 0),
        .he.rgba(119, 224, 80),
        .he.rgba(255, 109, 130),
        .he.rgba(141, 141, 141)
    ]
    
    @objc public class func `default`() -> HEImageEditorConfiguration {
        return HEImageEditorConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        HEImageEditorConfiguration.single = HEImageEditorConfiguration()
    }
    
    public var maxImageStickersCount = 1
    public var maxTextStickersCount = 1
    
    public static let imageStickerTrayHeight: CGFloat = 156
    /// 이미지 스티커 편집의 확인 버튼을 누를 때, 에디터를 완료시킬 지 여부
    ///
    /// - default: true
    public var actionDoneEditorWhenImageStickerEditingConfirm = true
    
    private var _tools: [HEImageEditorConfiguration.EditTool] = [.textSticker,  .imageSticker, .clip]
    
    /// Edit image tools.
    /// - warning: 이미지스티커를 포함할 경우, imageStickerTray: HEImageStickerTray를 꼭 설정해야 함.
    public var tools: [HEImageEditorConfiguration.EditTool] {
        get {
            if _tools.isEmpty {
                return [.textSticker,  .imageSticker, .clip]
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
    
    private var _clipRatios: [HEImageClipRatio] = [.origin, .custom, .wh1x1]
    /// Edit ratios for image editor.
    @objc public var clipRatios: [HEImageClipRatio] {
        get {
            if _clipRatios.isEmpty {
                return [.custom]
            } else {
                return _clipRatios
            }
        }
        set {
            _clipRatios = newValue
        }
    }
    
    private var _textStickerTextColors = HEImageEditorConfiguration.defaultTextColors
    /// Text sticker colors for image editor.
    @objc public var textStickerTextColors: [UIColor] {
        get {
            if _textStickerTextColors.isEmpty {
                return HEImageEditorConfiguration.defaultTextColors
            } else {
                return _textStickerTextColors
            }
        }
        set {
            _textStickerTextColors = newValue
        }
    }
    
    private var _textStickerBackgroundColors = HEImageEditorConfiguration.defaultTextFillColors
    /// Text sticker background colors for image editor.
    @objc public var textStickerBackgroundColors: [UIColor] {
        get {
            if _textStickerBackgroundColors.isEmpty {
                return HEImageEditorConfiguration.defaultTextFillColors
            } else {
                return _textStickerBackgroundColors
            }
        }
        set {
            _textStickerBackgroundColors = newValue
        }
    }
    
    
    @objc public var textStickerDefaultFont: UIFont?
    /// 텍스트 스티커에서 글줄 내리기 허용 여부
    @objc public var textStickerCanLineBreak = true
    @objc public var textStickerMaximumLines = 4
    @objc public var textStickerMaximumCharactersPerLine = 15
    /// 텍스트 스티커 배경 넣기 스타일
    @objc public var textStickerFillStyle: TextStickerFillStyle = TextStickerFillStyle.area
    
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
    
    @objc public var imageStickerTray: (UIView & HEImageStickerTray)?

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
}

public extension HEImageEditorConfiguration {
    
    @objc enum TextStickerFillStyle: Int {
        case area
        case character
    }
    
    @objc enum EditTool: Int {
        case draw
        case clip
        case imageSticker
        case textSticker
        case mosaicDraw
        case filter
        case adjust
        
        var label: String {
            return localLanguageTextValue("effect-" + self.name)
        }
        
        var name: String {
            switch self {
            case .draw: return "draw"
            case .clip: return "clip"
            case .imageSticker: return "imageSticker"
            case .textSticker: return "textSticker"
            case .mosaicDraw: return "mosaicDraw"
            case .filter: return "filter"
            case .adjust: return "adjust"
            }
        }
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
