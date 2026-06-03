//
//  Bundle+HEImageEditor.swift
//  HEImageEditor
//

import Foundation

private class BundleToken { }

extension Bundle {
    private static var bundle: Bundle?
    
    static var local: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }
    
    // ??
    static var spm_module: Bundle? = {
        let bundleName = "HEImageEditor_HEImageEditor"
        
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleToken.self).resourceURL,
            
            // For command-line tools.
            Bundle.main.bundleURL,
        ]
        
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    
}

extension Bundle {
    
    static var HEImageEditorBundle: Bundle? {
        return local
    }
    
    class func heLocalizedString(_ key: String) -> String {
        return localizedBundle.localizedString(forKey: key,
                                               value: "",
                                               table: "HEImageEditorLocalizable")
    }

    /// 기기 언어 설정에 맞는 .lproj 하위 번들.
    ///
    /// 기본 `NSLocalizedString` 은 호스트 앱이 지원하는 언어로 제한되므로,
    /// 앱이 한국어를 지원하지 않으면 라이브러리 문자열이 영어로 표시되어
    /// 한/영이 섞이는 문제가 있다. 기기의 실제 언어 설정(AppleLanguages)을
    /// 기준으로 번들을 직접 선택해 라이브러리 문자열이 기기 언어를 따르도록 한다.
    private static let localizedBundle: Bundle = {
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

extension String {
    func localized() -> String {
        return Bundle.heLocalizedString(self)
    }
}
