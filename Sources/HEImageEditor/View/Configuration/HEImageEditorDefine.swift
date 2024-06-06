//
//  HEImageEditorDefine.swift
//  HEImageEditor
//
import UIKit

struct HEImageEditorLayout {
    static let bottomToolBtnH: CGFloat = 34
    
    static let bottomToolTitleFont = UIFont.systemFont(ofSize: 17)
    
    static let bottomToolBtnCornerRadius: CGFloat = 5
}

func deviceIsiPhone() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

func deviceIsiPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    insets = UIApplication.shared.findKeyWindow()?.safeAreaInsets ?? .zero
    return insets
}
