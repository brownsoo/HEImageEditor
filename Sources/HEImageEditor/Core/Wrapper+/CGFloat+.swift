//
//  CGFloat+HEImageEditor.swift
//  HEImageEditor
//

import AVKit

extension HEImageEditorWrapper where Base == CGFloat {
    var toPi: CGFloat {
        return base / 180 * .pi
    }
}
