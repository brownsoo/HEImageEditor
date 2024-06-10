//
//  DebugLine.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/10/24.
//

import UIKit

protocol DebugLine {
    
}

extension DebugLine {
    func drawDebugOutline(_ color: UIColor = UIColor.red, fill: Bool = false, isFirst: Bool = true) {
        if let self = self as? UIView {
            self.layer.borderColor = color.withAlphaComponent(0.3).cgColor
            self.layer.borderWidth = isFirst ? 1.5: 0.5
            if fill {
                self.layer.backgroundColor = color.withAlphaComponent(0.2).cgColor
            }
            for child in self.subviews {
                if let s = child as? UIStackView {
                    s.arrangedSubviews.forEach {
                        ($0 as? DebugLine)?.drawDebugOutline(color, fill: fill, isFirst: false)
                    }
                } else {
                    (child as? DebugLine)?.drawDebugOutline(color, fill: fill, isFirst: false)
                }
            }
        }
    }
}
