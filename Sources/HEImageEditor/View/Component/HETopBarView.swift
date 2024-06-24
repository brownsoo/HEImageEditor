//
//  HETopBarView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/14/24.
//

import Foundation
import UIKit

open class HETopBarView: UIView {
    
    private var guideBottom: NSLayoutConstraint!
    private lazy var centerContainer = UIStackView()
    private lazy var trailingContainer = UIStackView()
    private lazy var leadingContainer = UIStackView()
    
    private lazy var shadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [HEEditImageViewController.shadowColorFrom, HEEditImageViewController.shadowColorTo]
        layer.locations = [0, 1]
        return layer
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func show(animate: Bool = true) {
        if animate {
            self.isHidden = false
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseOut], animations: {
                self.alpha = 1
            })
            UIView.animate(withDuration: 0.2, delay: 0.2, options: [.curveEaseOut], animations: {
                self.guideBottom?.constant = 0
            })
        } else {
            self.isHidden = false
            self.transform = .identity
            self.alpha = 1
        }
    }
    
    public func hide(animate: Bool = true) {
        if animate {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear], animations: {
                self.guideBottom?.constant = -12
                self.alpha = 0
            }) { _ in
                self.isHidden = true
            }
        } else {
            self.alpha = 0
            self.isHidden = true
            self.guideBottom?.constant = -12
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        shadowLayer.frame = self.bounds
    }
    
    public func setupUI() {
        
        self.addSubview(leadingContainer)
        self.addSubview(trailingContainer)
        self.addSubview(centerContainer)
        
        self.layer.addSublayer(shadowLayer)
        
        let guide = UILayoutGuide()
        self.addLayoutGuide(guide)
        guideBottom = guide.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: self.leftAnchor),
            guide.rightAnchor.constraint(equalTo: self.rightAnchor),
            guide.heightAnchor.constraint(equalToConstant: 44),
            guideBottom
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
