//
//  HEAdjustStatus.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/20/24.
//

import Foundation
/// 명도, 대비, 채도 변형 상태
public struct HEAdjustStatus {
    var brightness: Float = 0
    var contrast: Float = 0
    var saturation: Float = 0

    var allValueIsZero: Bool {
        brightness == 0 && contrast == 0 && saturation == 0
    }
    
    public init(
        brightness: Float = 0,
        contrast: Float = 0,
        saturation: Float = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
    }
}
