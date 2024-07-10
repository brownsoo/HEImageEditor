//
//  Bundle+.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation
import UIKit

extension Bundle {
    static var local: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }
}

private class BundleToken {}

internal func ypLocalized(_ str: String) -> String {
    return NSLocalizedString(str,
                             tableName: "HEImagePickerLocalizable",
                             bundle: Bundle.local,
                             value: "",
                             comment: "")
}

internal func imageFromBundle(_ named: String) -> UIImage? {
    return UIImage(named: named, in: Bundle.local, compatibleWith: nil)
}

public struct HEPickerIcons {

    public var shouldChangeDefaultBackButtonIcon = false
    public var hideBackButtonTitle = true

    public var editImageIcon = imageFromBundle("icMagicbar") ?? UIImage(systemName: "wand.and.rays")
    public var backButtonIcon = imageFromBundle("icArrowRight") ?? UIImage(systemName: "chevron.left")
    public var arrowDownIcon = imageFromBundle("icArrowDown") ?? UIImage(systemName: "chevron.down")
    public var cropIcon = UIImage(systemName: "crop")
    
    public var captureVideoOnImage: UIImage? = imageFromBundle("yp_iconVideoCaptureRecording")
    public var playImage: UIImage? = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular, scale: .large))
    public var removeImage: UIImage? = UIImage(systemName: "x.circle")
    // 16x16
    public var cameraFillIcon = imageFromBundle("icCameraFill") ?? UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default))
    // 16x16
    public var videoFillIcon: UIImage? = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default))
}
