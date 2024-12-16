//
//  DarkLightSwitch.swift
//  HEExample
//
//  Created by 브라운수 on 7/29/24.
//

import Foundation
import UIKit


class DrakLightSwitch: UIControl {
    private let label = UILabel()
    let swit = UISwitch()
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.text = "Dark"
        swit.isOn = self.traitCollection.userInterfaceStyle == .dark
        swit.addTarget(self, action: #selector(onValueChanged), for: .valueChanged)
        addSubview(label)
        addSubview(swit)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        swit.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: leftAnchor).with(priority: .defaultHigh),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0).with(priority: .defaultHigh),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).with(priority: .defaultHigh),
            label.rightAnchor.constraint(equalTo: swit.leftAnchor, constant: -4),
            swit.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
            swit.topAnchor.constraint(equalTo: topAnchor, constant: 0).with(priority: .defaultHigh + 1),
            swit.bottomAnchor.constraint(equalTo: bottomAnchor).with(priority: .defaultHigh + 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onValueChanged() {
        let isDark = swit.isOn
        let keyWindow = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.filter({ $0.isKeyWindow }).first
        keyWindow?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
}

extension NSLayoutConstraint {
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

