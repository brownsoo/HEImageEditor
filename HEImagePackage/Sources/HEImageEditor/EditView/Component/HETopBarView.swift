//
//  HETopBarView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/14/24.
//

import Foundation
import UIKit

open class HETopBarView: UIView {
    
    static var contentHeight: CGFloat = 48
    
    private lazy var centerContainer = UIStackView()
    private lazy var trailingContainer = UIStackView()
    private lazy var leadingContainer = UIStackView()
    private var shouldShow = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func show(animate: Bool = false) {
        shouldShow = true
        if animate {
            self.isHidden = false
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                self.alpha = 1
            })
        } else {
            self.isHidden = false
            self.alpha = 1
        }
    }
    
    public func hide(animate: Bool = false) {
        shouldShow = false
        if animate {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
                self.alpha = 0
            }) { _ in
                if !self.shouldShow {
                    self.isHidden = true
                }
            }
        } else {
            self.alpha = 0
            self.isHidden = true
            self.layoutIfNeeded()
        }
    }
    
    public func addLeadingView(_ v: UIView) {
        leadingContainer.addArrangedSubview(v)
    }
    
    public func addTrailingView(_ v: UIView) {
        trailingContainer.addArrangedSubview(v)
    }
    
    public func addCenterView(_ v: UIView) {
        centerContainer.addArrangedSubview(v)
    }
    
    
    public func setupUI() {
        
        self.addSubview(leadingContainer)
        self.addSubview(trailingContainer)
        self.addSubview(centerContainer)
        
        let guide = UILayoutGuide()
        self.addLayoutGuide(guide)
        
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: self.leftAnchor),
            guide.rightAnchor.constraint(equalTo: self.rightAnchor),
            guide.heightAnchor.constraint(equalToConstant: Self.contentHeight),
            guide.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        centerContainer.also { it in
            it.axis = .horizontal
            it.alignment = .bottom
            it.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            it.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
                it.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
                it.leadingAnchor.constraint(greaterThanOrEqualTo: leadingContainer.trailingAnchor),
                it.trailingAnchor.constraint(lessThanOrEqualTo: trailingContainer.leadingAnchor),
                it.widthAnchor.constraint(equalToConstant: 0).withPriority(.fittingSizeLevel),
                it.heightAnchor.constraint(equalToConstant: 0).withPriority(.fittingSizeLevel),
            ])
        }
        
        leadingContainer.also { it in
            it.axis = .horizontal
            it.alignment = .bottom
            it.setContentHuggingPriority(.defaultLow, for: .horizontal)
            it.setContentCompressionResistancePriority(.required, for: .horizontal)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
                it.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                it.widthAnchor.constraint(equalToConstant: 0).withPriority(.defaultLow),
            ])
        }
        
        trailingContainer.also { it in
            it.axis = .horizontal
            it.alignment = .bottom
            it.setContentHuggingPriority(.defaultLow, for: .horizontal)
            it.setContentCompressionResistancePriority(.required, for: .horizontal)
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
                it.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                it.widthAnchor.constraint(equalToConstant: 0).withPriority(.defaultLow),
            ])
        }
    }
}
