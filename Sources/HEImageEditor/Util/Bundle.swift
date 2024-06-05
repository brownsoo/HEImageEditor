//
//  Bundle+HEImageEditor.swift
//  HEImageEditor
//

import Foundation

private class BundleFinder { }

extension Bundle {
    private static var bundle: Bundle?
    
    static var normal_module: Bundle? = {
        let bundleName = "HEImageEditor"

        var candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: HEEditImageViewController.self).resourceURL,
            
            // For command-line tools.
            Bundle.main.bundleURL,
        ]
        
        #if SWIFT_PACKAGE
            // For SWIFT_PACKAGE.
            candidates.append(Bundle.module.bundleURL)
        #endif

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    
    static var spm_module: Bundle? = {
        let bundleName = "HEImageEditor_HEImageEditor"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,
            
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
    
    static var HEImageEditorBundle: Bundle? {
        return normal_module ?? spm_module
    }
    
    class func resetLanguage() {
        bundle = nil
    }
    
    class func zlLocalizedString(_ key: String) -> String {
        if bundle == nil {
            guard let path = Bundle.HEImageEditorBundle?.path(forResource: HEImageEditorUIConfiguration.default().languageType.key, ofType: "lproj") else {
                return ""
            }
            bundle = Bundle(path: path)
        }
        
        let value = bundle?.localizedString(forKey: key, value: nil, table: nil)
        return Bundle.main.localizedString(forKey: key, value: value, table: nil)
    }
}
