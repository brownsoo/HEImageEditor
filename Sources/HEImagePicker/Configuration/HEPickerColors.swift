//
//  HPColors.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

public struct HEPickerColors {
    
    // MARK: - Common
    
    /// The common tint color which is used for done buttons in navigation bar, multiple items selection and so on.
    public var tintColor = UIColor.ypSystemBlue
    
    /// A color for navigation bar spinner.
    /// Default is nil, which is default iOS gray UIActivityIndicator.
    public var navigationBarActivityIndicatorColor: UIColor?
    
    /// A color for circle for selected items in multiple selection
    /// Default is nil, which takes tintColor.
    public var multipleItemsSelectedCircleColor: UIColor?
    
    /// The background color of the bottom of photo and video screens.
    public var photoVideoScreenBackgroundColor: UIColor = .offWhiteOrBlack

    /// The background color of the library and space between collection view cells.
    public var libraryScreenBackgroundColor: UIColor = .offWhiteOrBlack

    /// A color for background of the asset container. You can see it when bouncing the image.
    public var assetViewBackgroundColor: UIColor = .offWhiteOrBlack
    
    // MARK: - Trimmer
    
    /// The color of the main border of the view
    public var trimmerMainColor: UIColor = .ypLabel
    /// The color of the handles on the side of the view
    public var trimmerHandleColor: UIColor = .ypSystemBackground
    /// The color of the position indicator
    public var positionLineColor: UIColor = .ypSystemBackground
    
    // MARK: - Cover selector
    
    /// The color of the cover selector border
    public var coverSelectorBorderColor: UIColor = .offWhiteOrBlack
    
    // MARK: - Progress bar
    
    /// The color for the progress bar when processing video or images. The all track color.
    public var progressBarTrackColor: UIColor = .ypSystemBackground
    /// The color of completed track for the progress bar
    public var progressBarCompletedColor: UIColor?
    
    /// The color of the Album's NavigationBar background
    public var albumBarTintColor: UIColor = .ypSystemBackground
    /// The color of the Album's left and right items color
    public var albumTintColor: UIColor = .ypLabel
    /// The color of the Album's title color
    public var albumTitleColor: UIColor = .ypLabel
}


extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    static var offWhiteOrBlack: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                let rgbValue: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0 : 247
                return UIColor(r: rgbValue, g: rgbValue, b: rgbValue)
            }
        } else {
            return UIColor(r: 247, g: 247, b: 247)
        }
    }
    
    /// The color for text labels that contain primary content.
    ///
    /// Like `.label`, but backwards-compatible with iOS 12 and lower.
    static var ypLabel: UIColor {
        if #available(iOS 13, *) {
            return .label
        }
        return .black
    }
    
    static var ypSecondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }
        return UIColor(r: 153, g: 153, b: 153)
    }
    
    /// The color for content layered on top of the main background.
    ///
    /// Like `.secondarySystemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSecondarySystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemBackground
        }
        return UIColor(r: 247, g: 247, b: 247)
    }
    
    /// The color for the main background of your interface.
    ///
    /// Like `.systemBackground`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return .white
    }
    
    /// The base blue color.
    ///
    static var ypSystemBlue: UIColor {
        return UIColor(r: 71, g: 120, b: 222)
    }
    
    /// The base gray color.
    ///
    /// Like `.systemGray`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemGray: UIColor {
        if #available(iOS 13, *) {
            return .systemGray
        }
        return .gray
    }
    
    /// The color for red, compatible with dark mode in iOS 13.
    ///
    /// Like `.red`, but backwards-compatible with iOS 12 and lower.
    static var ypSystemRed: UIColor {
        if #available(iOS 13, *) {
            return .systemRed
        }
        return .red
        
    }
}
