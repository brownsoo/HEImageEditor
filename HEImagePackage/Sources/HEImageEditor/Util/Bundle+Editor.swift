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
        return NSLocalizedString(key,
                                 tableName: "HEImageEditorLocalizable",
                                 bundle: Bundle.local,
                                 value: "",
                                 comment: "")
    }
}

extension String {
    func localized() -> String {
        return Bundle.heLocalizedString(self)
    }
}
