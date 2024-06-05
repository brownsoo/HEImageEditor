//
//  ImageStickerEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public class HEImageStickerEffect: HEOverlayEffect {
    public var resized: CGFloat
    public var frame: CGRect
    public var rotated: CGFloat
    public var zIndex: Int = 0
    public var undoable: Bool { true }
    public var stickerId: String
    public var content: URL
    public var name: String?
    
    public init(stickerId: String, content: URL, name: String? = nil) {
        self.stickerId = stickerId
        self.content = content
        self.name = name
        self.frame = CGRect(x: 0, y: 0, width: 200, height: 200) // 기본 사이즈
        self.resized = 1
        self.rotated = 0
    }
    
    public func tranlate(x: CGFloat, y: CGFloat) {
        self.frame = frame.offsetBy(dx: x, dy: y)
    }
    
}
