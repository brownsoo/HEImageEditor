//
//  TransformEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public class TransformEffect: HEBitmapEffect {
    public var zIndex: Int = -1
    public var undoable: Bool { true }
    public var scale: CGFloat
    public var rotation: CGFloat
    
    public init(scale: CGFloat, rotation: CGFloat) {
        self.scale = scale
        self.rotation = rotation
    }
    
}
