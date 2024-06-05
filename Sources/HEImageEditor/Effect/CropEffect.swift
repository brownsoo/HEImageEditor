//
//  CropEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation

public class CropEffect: HEBitmapEffect {
    public var zIndex: Int = -1
    public var undoable: Bool { false }
    public var cropRect: CGRect
    
    public init(cropRect: CGRect) {
        self.cropRect = cropRect
    }
}
