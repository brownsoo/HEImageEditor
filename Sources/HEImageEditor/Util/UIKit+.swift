//
//  UIKit+.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/5/24.
//

import UIKit
import HECommon

func deviceIsiPhone() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

func deviceIsiPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    insets = UIApplication.shared.he.findKeyWindow()?.safeAreaInsets ?? .zero
    return insets
}

extension HEWrapper where Base: UIColor {
    static var adjustSliderNormalColor: UIColor {
        HEImageEditorUIConfiguration.default().adjustSliderNormalColor
    }
    
    static var adjustSliderTintColor: UIColor {
        HEImageEditorUIConfiguration.default().adjustSliderTintColor
    }
    
    static var editDoneBtnBgColor: UIColor {
        HEImageEditorUIConfiguration.default().editDoneBtnBgColor
    }
    
    static var editDoneBtnTitleColor: UIColor {
        HEImageEditorUIConfiguration.default().editDoneBtnTitleColor
    }
    
    static var trashbinNormalBgColor: UIColor {
        HEImageEditorUIConfiguration.default().ashbinNormalBgColor
    }
    
    static var trashbinTintBgColor: UIColor {
        HEImageEditorUIConfiguration.default().ashbinTintBgColor
    }
    
    static var toolTitleNormalColor: UIColor {
        HEImageEditorUIConfiguration.default().toolTitleNormalColor
    }
    
    static var toolTitleTintColor: UIColor {
        HEImageEditorUIConfiguration.default().toolTitleTintColor
    }

    static var toolIconHighlightedColor: UIColor? {
        HEImageEditorUIConfiguration.default().toolIconHighlightedColor
    }
}


extension HEWrapper where Base: UIImage {
    /// 사진 밝기, 대비, 채도 조정
    /// - Parameters:
    ///   - brightness: value in [-1, 1]
    ///   - contrast: value in [-1, 1]
    ///   - saturation: value in [-1, 1]
    func adjust(brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return base
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(HEImageEditorConfiguration.AdjustTool.brightness.filterValue(brightness), forKey: HEImageEditorConfiguration.AdjustTool.brightness.key)
        filter?.setValue(HEImageEditorConfiguration.AdjustTool.contrast.filterValue(contrast), forKey: HEImageEditorConfiguration.AdjustTool.contrast.key)
        filter?.setValue(HEImageEditorConfiguration.AdjustTool.saturation.filterValue(saturation), forKey: HEImageEditorConfiguration.AdjustTool.saturation.key)
        let outputCIImage = filter?.outputImage
        return outputCIImage?.he.toUIImage()
    }
    
    static func getImage(_ named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle.HEImageEditorBundle, compatibleWith: nil)
    }
}

extension UIViewController {
    @discardableResult
    func showAlert(_ text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return self.showAlert(title: nil, text: text, confirmAction: confirmAction)
    }
    
    @discardableResult
    func showAlert(title: String? = nil, text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        DispatchQueue.main.async {
            let okayAction = UIAlertAction(title: Bundle.heLocalizedString("confirm"), style: .default, handler: confirmAction)
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
        return alert
    }
}

extension UIEdgeInsets {
    var width: CGFloat {
        self.left + self.right
    }
    var height: CGFloat {
        self.top + self.bottom
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
