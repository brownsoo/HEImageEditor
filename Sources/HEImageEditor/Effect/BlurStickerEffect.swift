//
//  HEBlurStickerEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import CoreGraphics

public class BlurStickerEffect: HEOverlayEffect, Codable {
    public var resized: CGFloat
    public var frame: CGRect
    public var rotated: CGFloat
    public var zIndex: Int = 0
    public var undoable: Bool { true }
    public var blurRadius: CGFloat
    public var blurType: Int
    
    init(blurRadius: CGFloat = 10, blurType: Int = 0) {
        self.blurRadius = blurRadius
        self.blurType = blurType
        self.frame = CGRect(x: 0, y: 0, width: 200, height: 200) // 기본 사이즈
        self.resized = 1
        self.rotated = 0
    }
    
    enum CodingKeys: CodingKey {
        case resized
        case frame
        case rotated
        case zIndex
        case blurRadius
        case blurType
    }
        
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.resized = try container.decode(CGFloat.self, forKey: .resized)
        self.frame = try container.decode(CGRect.self, forKey: .frame)
        self.rotated = try container.decode(CGFloat.self, forKey: .rotated)
        self.zIndex = try container.decode(Int.self, forKey: .zIndex)
        self.blurRadius = try container.decode(CGFloat.self, forKey: .blurRadius)
        self.blurType = try container.decode(Int.self, forKey: .blurType)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.resized, forKey: .resized)
        try container.encode(self.frame, forKey: .frame)
        try container.encode(self.rotated, forKey: .rotated)
        try container.encode(self.zIndex, forKey: .zIndex)
        try container.encode(self.blurRadius, forKey: .blurRadius)
        try container.encode(self.blurType, forKey: .blurType)
    }
    
    public func tranlate(x: CGFloat, y: CGFloat) {
        self.frame = frame.offsetBy(dx: x, dy: y)
    }
}

