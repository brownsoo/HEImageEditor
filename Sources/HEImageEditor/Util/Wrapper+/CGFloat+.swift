//
//  CGFloat+HEImageEditor.swift
//  HEImageEditor
//

import AVKit

extension HEWrapper where Base == CGFloat {
    var toPi: CGFloat {
        return base / 180 * .pi
    }
}
