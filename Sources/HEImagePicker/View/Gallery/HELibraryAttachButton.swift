//
//  LibraryAttachButton.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/8/24.
//

import Foundation
import UIKit

class HELibraryAttachButton: UIControl {
    
    private let enabledColor = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor.label : UIColor.black
    }
    private let disabledColor = UIColor { trait in
        return trait.userInterfaceStyle == .dark ? UIColor.label.withAlphaComponent(0.6)
            : UIColor(white: 187 / 255.0, alpha: 1.0)
    }
    private let label = UILabel()
    let countLabel = UILabel()
    
    override var isEnabled: Bool {
        didSet {
            label.textColor = isEnabled ? enabledColor : disabledColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.text = PickerConfig.wordings.attach
        label.textColor = .label
        label.font = PickerConfig.fonts.rightBarButtonFont
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .natural
        
        countLabel.font = PickerConfig.fonts.rightBarButtonFont
        countLabel.textColor = UIColor(r: 71, g: 120, b: 222)
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        addSubview(countLabel)
        addSubview(label)
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).with(priority: .defaultHigh),
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0).with(priority: .defaultHigh),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).with(priority: .defaultHigh),
            countLabel.rightAnchor.constraint(equalTo: label.leftAnchor, constant: -4),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0).with(priority: .defaultHigh + 1),
            label.bottomAnchor.constraint(equalTo: bottomAnchor).with(priority: .defaultHigh + 1)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
