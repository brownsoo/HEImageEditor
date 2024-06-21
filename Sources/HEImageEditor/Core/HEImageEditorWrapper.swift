//
//  HEImageEditorWrapper.swift
//  HEImageEditor

import Foundation
import UIKit

/// HE 스콥을 정하는 모델
public struct HEImageEditorWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

/// HE 변환 모델 
public protocol HEImageEditorCompatible: AnyObject { }
extension HEImageEditorCompatible {
    public var he: HEImageEditorWrapper<Self> {
        get { HEImageEditorWrapper(self) }
        set { }
    }
    
    public static var he: HEImageEditorWrapper<Self>.Type {
        get { HEImageEditorWrapper<Self>.self }
        set { }
    }
}

extension UIImage: HEImageEditorCompatible { }
extension CIImage: HEImageEditorCompatible { }
extension UIColor: HEImageEditorCompatible { }
extension UIView: HEImageEditorCompatible { }
extension UIGraphicsImageRenderer: HEImageEditorCompatible { }



public protocol HEImageEditorCompatibleValue { }
extension HEImageEditorCompatibleValue {
    public var he: HEImageEditorWrapper<Self> {
        get { HEImageEditorWrapper(self) }
        set { }
    }
}

extension String: HEImageEditorCompatibleValue { }
extension CGFloat: HEImageEditorCompatibleValue { }
