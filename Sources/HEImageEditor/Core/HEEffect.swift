//
//  HEEffect.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/3/24.
//

import Foundation

public enum HEEfectLevel: Int {
    case pixel = 0
    case filtering = 10
    case floating = 20
    case max = 100
}

public protocol HEEffect: Codable {
    /// 큰 범위의 효과 순서
    var level: HEEfectLevel { get }
    /// 레벨 안에서의 순서
    var zIndex: Int { get set }
    /// 순서 변경 가능 여부
    var zIndexable: Bool { get }
    /// 되돌리가능 여부, 불가하면 이전 이펙트들도 되돌릴 수 없음
    var undoable: Bool { get }
    
    func apply(image: HEImage)
}

public extension HEEffect {
    func apply(image: HEImage) {
        image.applyEffect(self)
    }
}

/// 이미지 비트맵에 바로 적용되는 효과
public protocol HEBitmapEffect: HEEffect {
}

public extension HEBitmapEffect {
    var level: HEEfectLevel { .pixel }
    var zIndex: Int { 0 }
    var zIndexable: Bool { false }
}

/// 이미지 위에 오버레이로 적용되는 효과
public protocol HEOverlayEffect: HEEffect, HETransfomable {
    var frame: CGRect { get }
}

public extension HEOverlayEffect {
    var level: HEEfectLevel { .floating }
    var zIndexable: Bool { true }
}

