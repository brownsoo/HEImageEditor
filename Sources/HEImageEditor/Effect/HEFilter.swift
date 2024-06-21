//
//  HEFilter.swift
//  HEImageEditor
//

import UIKit

/// https://github.com/Yummypets/YPImagePicker

public typealias HEFilterApplier = (_ image: UIImage) -> UIImage

@objc public enum HEFilterType: Int, Codable {
    case normal
    case chrome
    case fade
    case instant
    case process
    case transfer
    case tone
    case linear
    case sepia
    case mono
    case noir
    case tonal
    
    var coreImageFilterName: String {
        switch self {
        case .normal:
            return ""
        case .chrome:
            return "CIPhotoEffectChrome"
        case .fade:
            return "CIPhotoEffectFade"
        case .instant:
            return "CIPhotoEffectInstant"
        case .process:
            return "CIPhotoEffectProcess"
        case .transfer:
            return "CIPhotoEffectTransfer"
        case .tone:
            return "CILinearToSRGBToneCurve"
        case .linear:
            return "CISRGBToneCurveToLinear"
        case .sepia:
            return "CISepiaTone"
        case .mono:
            return "CIPhotoEffectMono"
        case .noir:
            return "CIPhotoEffectNoir"
        case .tonal:
            return "CIPhotoEffectTonal"
        }
    }
}

public class HEFilter: NSObject {
    public var name: String
    
    let applier: HEFilterApplier?
    
    @objc public init(name: String, filterType: HEFilterType) {
        self.name = name
        
        if filterType != .normal {
            applier = { image -> UIImage in
                guard let ciImage = image.he.toCIImage() else {
                    return image
                }
                
                let filter = CIFilter(name: filterType.coreImageFilterName)
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                guard let outputImage = filter?.outputImage?.he.toUIImage() else {
                    return image
                }
                return outputImage
            }
        } else {
            applier = nil
        }
    }
    
    @objc public init(name: String, applier: HEFilterApplier?) {
        self.name = name
        self.applier = applier
    }
}

extension HEFilter {
    class func clarendonFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.he.toCIImage() else {
            return image
        }
        
        let backgroundImage = getColorImage(red: 127, green: 187, blue: 227, alpha: Int(255 * 0.2),
                                            rect: ciImage.extent)
        let outputCIImage = ciImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": backgroundImage,
        ])
        .applyingFilter("CIColorControls", parameters: [
            "inputSaturation": 1.35,
            "inputBrightness": 0.05,
            "inputContrast": 1.1,
        ])
        guard let outputImage = outputCIImage.he.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func nashvilleFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.he.toCIImage() else {
            return image
        }
        
        let backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56),
                                            rect: ciImage.extent)
        let backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4),
                                             rect: ciImage.extent)
        let outputCIImage = ciImage
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage,
            ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2,
            ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1,
            ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage2,
            ])
        
        guard let outputImage = outputCIImage.he.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func apply1977Filter(image: UIImage) -> UIImage {
        guard let ciImage = image.he.toCIImage() else {
            return image
        }
        
        let filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: ciImage.extent)
        let backgroundImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05,
            ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3,
            ])
        
        let outputCIImage = filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage,
            ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1),
            ])
        
        guard let outputImage = outputCIImage.he.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func toasterFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.he.toCIImage() else {
            return image
        }
        
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1,
        ])?.outputImage?.cropped(to: ciImage.extent)
        
        let outputCIImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1,
            ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": circle!,
            ])
        
        guard let outputImage = outputCIImage.he.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(red: CGFloat(Double(red) / 255.0),
                       green: CGFloat(Double(green) / 255.0),
                       blue: CGFloat(Double(blue) / 255.0),
                       alpha: CGFloat(Double(alpha) / 255.0))
    }
    
    class func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let color = getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(color: color).cropped(to: rect)
    }
}

public extension HEFilter {
    @objc static let all: [HEFilter] = [.normal, .clarendon, .nashville, .apply1977, .toaster, .chrome, .fade, .instant, .process, .transfer, .tone, .linear, .sepia, .mono, .noir, .tonal]
    
    @objc static let normal = HEFilter(name: "Normal", filterType: .normal)
    
    @objc static let clarendon = HEFilter(name: "Clarendon", applier: HEFilter.clarendonFilter)
    
    @objc static let nashville = HEFilter(name: "Nashville", applier: HEFilter.nashvilleFilter)
    
    @objc static let apply1977 = HEFilter(name: "1977", applier: HEFilter.apply1977Filter)
    
    @objc static let toaster = HEFilter(name: "Toaster", applier: HEFilter.toasterFilter)
    
    @objc static let chrome = HEFilter(name: "Chrome", filterType: .chrome)
    
    @objc static let fade = HEFilter(name: "Fade", filterType: .fade)
    
    @objc static let instant = HEFilter(name: "Instant", filterType: .instant)
    
    @objc static let process = HEFilter(name: "Process", filterType: .process)
    
    @objc static let transfer = HEFilter(name: "Transfer", filterType: .transfer)
    
    @objc static let tone = HEFilter(name: "Tone", filterType: .tone)
    
    @objc static let linear = HEFilter(name: "Linear", filterType: .linear)
    
    @objc static let sepia = HEFilter(name: "Sepia", filterType: .sepia)
    
    @objc static let mono = HEFilter(name: "Mono", filterType: .mono)
    
    @objc static let noir = HEFilter(name: "Noir", filterType: .noir)
    
    @objc static let tonal = HEFilter(name: "Tonal", filterType: .tonal)
}
