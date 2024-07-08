//
//  HEImageEditorWrapper.swift
//  HEImageEditor

import Foundation
import UIKit

/// HE 스콥을 정하는 모델
public struct HEWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

/// for Class type
public protocol HECompatible: AnyObject { }
extension HECompatible {
    public var he: HEWrapper<Self> {
        get { HEWrapper(self) }
        set { }
    }
    
    public static var he: HEWrapper<Self>.Type {
        get { HEWrapper<Self>.self }
        set { }
    }
}

extension UIApplication: HECompatible { }
extension UIImage: HECompatible { }
extension CIImage: HECompatible { }
extension UIColor: HECompatible { }
extension UIView: HECompatible { }
extension UIGraphicsImageRenderer: HECompatible { }

/// for Value type

public protocol HECompatibleValue { }
extension HECompatibleValue {
    public var he: HEWrapper<Self> {
        get { HEWrapper(self) }
        set { }
    }
}

extension String: HECompatibleValue { }
extension CGFloat: HECompatibleValue { }
extension Data: HECompatibleValue { }
