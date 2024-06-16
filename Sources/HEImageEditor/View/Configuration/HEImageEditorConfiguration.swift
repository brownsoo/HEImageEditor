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
    
    private var _clipRatios: [HEImageClipRatio] = [.custom]
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
    enum EditTool: String {
        case draw
        case clip
        case imageSticker
        case textSticker
        case mosaic
        case filter
        case adjust
        
        var label: String {
            return localLanguageTextValue("effect-" + self.rawValue)
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

// MARK: Clip ratio.

public class HEImageClipRatio: NSObject {
    @objc public var title: String
    @objc public var whRatio: CGFloat
    @objc public let iconName: String
    @objc public let isCircle: Bool
    
    @objc 
    public init(title: String, whRatio: CGFloat, iconName: String, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.iconName = iconName
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
    
    @objc static let origin = HEImageClipRatio(title: "original", whRatio: 0, iconName: "icEditThumOriginal")
    @objc static let custom = HEImageClipRatio(title: "custom ratio", whRatio: 0, iconName: "icEditThumFree")
    @objc static let circle = HEImageClipRatio(title: "circle", whRatio: 1, iconName: "icEditThumSquare", isCircle: true)
    
    @objc static let wh1x1 = HEImageClipRatio(title: "1 : 1", whRatio: 1, iconName: "icEditThumSquare")
    @objc static let wh3x4 = HEImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0, iconName: "icEditThumSquare")
    @objc static let wh4x3 = HEImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0, iconName: "icEditThumSquare")
    @objc static let wh2x3 = HEImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0, iconName: "icEditThumSquare")
    @objc static let wh3x2 = HEImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0, iconName: "icEditThumSquare")
    @objc static let wh9x16 = HEImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0, iconName: "icEditThumSquare")
    @objc static let wh16x9 = HEImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0, iconName: "icEditThumSquare")
}

/// 이미지 스티커 원본
@objc public class HEImageSticker: NSObject {
    
    public static var faceAiIcon: HEImageSticker = {
        HEImageSticker(id: idFaceAi, image: UIImage.he.getImage("editStickerFaceAi") ?? UIImage(systemName: "faceid")!)
        
    }()
    
    public static var mosaicIcon: HEImageSticker = {
        HEImageSticker(id: idMosaic, image: UIImage.he.getImage("editStickerMosaic") ?? UIImage(systemName: "mosaic")!)
    }()
    static let idFaceAi = "editStickerFaceAi"
    static let idMosaic = "editStickerMosaic"
    
    public var isSpecialSticker: Bool { self.id == Self.idMosaic || self.id == Self.idFaceAi }
    
    public let id: String
    public let image: UIImage
    
    public init(id: String, image: UIImage) {
        self.id = id
        self.image = image // TODO: lazy loading
    }
}

/// 이미지 스티커 뷰 대상
@objc public protocol HEImageStickerTray {
    var selectImageBlock: ((HEImageSticker) -> Void)? { get set }
    var hideBlock: (() -> Void)? { get set }
    func show(in parent: UIView, frame: CGRect)
    func hide()
    func randomSticker(inSection section: Int) -> HEImageSticker?
}
