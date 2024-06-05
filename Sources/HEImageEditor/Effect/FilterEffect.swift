//
//  FilterEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public class FilterEffect: HEBitmapEffect {
    public var zIndex: Int = 0
    public var level: HEEfectLevel { .filtering }
    public var intensity: CGFloat
    public var undoable: Bool { true }
    
    init(intensity: CGFloat) {
        self.intensity = intensity
    }
}
