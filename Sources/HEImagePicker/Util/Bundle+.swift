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

internal func imageFromBundle(_ named: String) -> UIImage {
    return UIImage(named: named, in: Bundle.local, compatibleWith: nil) ?? UIImage()
}

public struct HEPickerIcons {

    public var shouldChangeDefaultBackButtonIcon = false
    public var hideBackButtonTitle = true
    
    public var backButtonIcon: UIImage = imageFromBundle("icArrowRight")
    public var arrowDownIcon: UIImage = imageFromBundle("icArrowDown")
    public var cropIcon: UIImage = imageFromBundle("yp_iconCrop")
    public var flashOnIcon: UIImage = imageFromBundle("yp_iconFlash_on")
    public var flashOffIcon: UIImage = imageFromBundle("yp_iconFlash_off")
    public var flashAutoIcon: UIImage = imageFromBundle("yp_iconFlash_auto")
    public var loopIcon: UIImage = imageFromBundle("yp_iconLoop")
    public var multipleSelectionOnIcon: UIImage = imageFromBundle("yp_multiple_colored")
    public var capturePhotoImage: UIImage = imageFromBundle("yp_iconCapture")
    public var captureVideoImage: UIImage = imageFromBundle("yp_iconVideoCapture")
    public var captureVideoOnImage: UIImage = imageFromBundle("yp_iconVideoCaptureRecording")
    public var playImage: UIImage = imageFromBundle("yp_play")
    public var removeImage: UIImage = imageFromBundle("yp_remove")
}
