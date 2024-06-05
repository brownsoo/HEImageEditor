//
//  TextStickerEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import CoreGraphics
import UIKit

public class TextStickerEffect: HEOverlayEffect {
    public enum Alignment: Int, Codable {
        case leading, center, trailing
    }
    
    public var resized: CGFloat
    public var frame: CGRect
    public var rotated: CGFloat
    public var zIndex: Int = 0
    public var undoable: Bool { true }
    
    public let text: String
    public let fontName: String?
    public let fontSize: CGFloat
    public let color: HEColor
    public let alignment: Alignment
    
    public init(text: String,
         fontName: String?, 
         fontSize: CGFloat = 20,
         color: HEColor = .init(white: 1.0, alpha: 1.0),
         alignment: Alignment = .leading) {
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.color = color
        self.alignment = alignment
        self.frame = CGRect(x: 0, y: 0, width: 200, height: 200) // 기본 사이즈
        self.resized = 1
        self.rotated = 0
    }
    
    public func tranlate(x: CGFloat, y: CGFloat) {
        self.frame = frame.offsetBy(dx: x, dy: y)
    }
}
