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

    /// 기기 언어 설정에 맞는 .lproj 하위 번들.
    ///
    /// 기본 `NSLocalizedString` 은 호스트 앱이 지원하는 언어로 제한되므로,
    /// 앱이 한국어를 지원하지 않으면 라이브러리 문자열이 영어로 표시되어
    /// 한/영이 섞이는 문제가 있다. 기기의 실제 언어 설정(AppleLanguages)을
    /// 기준으로 번들을 직접 선택해 라이브러리 문자열이 기기 언어를 따르도록 한다.
    ///
    /// 같은 파일의 자유 함수 `pickerLocalized(_:)` 에서 접근하므로 `fileprivate`.
    fileprivate static let localizedBundle: Bundle = {
        let base = Bundle.local
        let deviceLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages")
            ?? Locale.preferredLanguages
        let matched = Bundle.preferredLocalizations(from: base.localizations,
                                                    forPreferences: deviceLanguages)
        guard let language = matched.first,
              let path = base.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            return base
        }
        return languageBundle
    }()
}

private class BundleToken {}

internal func pickerLocalized(_ str: String) -> String {
    return Bundle.localizedBundle.localizedString(forKey: str,
                                                  value: "",
                                                  table: "HEImagePickerLocalizable")
}

internal func imageFromBundle(_ named: String) -> UIImage? {
    return UIImage(named: named, in: Bundle.local, compatibleWith: nil)
}

public struct HEPickerIcons {

    public var shouldChangeDefaultBackButtonIcon = false
    public var hideBackButtonTitle = true

    public var editImageIcon = UIImage(systemName: "wand.and.rays", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))
    public var backButtonIcon = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))
    public var arrowDownIcon = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default))
    public var cropIcon = UIImage(systemName: "crop", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white, renderingMode: .alwaysOriginal)
    
    public var captureVideoOnImage: UIImage? = imageFromBundle("yp_iconVideoCaptureRecording")
    
    public var playImage: UIImage? = imageFromBundle("icPlayCircleLine52") ?? UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 52, weight: .regular, scale: .large))
    
    public var removeImage: UIImage? = UIImage(systemName: "x.circle")
    // 16x16
    public var cameraFillIcon: UIImage? = imageFromBundle("icCameraFill") ?? UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default))

    // 16x16
    public var videoFillIcon: UIImage? = UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .default))
    
    // 56x56
    public var emptyPhotoIcon: UIImage? = imageFromBundle("icImageFill") ?? UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular, scale: .default))?.withTintColor(.init(white: 204/255.0, alpha: 1.0), renderingMode: .alwaysOriginal)
}


extension String {
    func localized() -> String {
        return pickerLocalized(self)
    }
}
