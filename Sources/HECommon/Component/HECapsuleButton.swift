//
//  CapsuleButton.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import UIKit

extension UIControl.State: Hashable {
    public var hashValue: Int {
        return Int((6777*self.rawValue+3777) % UInt(UInt16.max))
    }
}

open class HECapsuleButton: UIButton {
    
    private var backgroundColors: [UIControl.State: UIColor] = [
        .normal: UIColor.white
    ]
    
    private var borderColors: [UIControl.State: UIColor] = [
        .normal: UIColor.clear
    ]
    
    private var borderWidths: [UIControl.State: CGFloat] = [
        .normal: 0
    ]
    
    private var capsuleLayer: CALayer?
    
    convenience init(title: String? = nil, isSelected: Bool = false) {
        self.init(frame: .zero)
        self.setTitle(title, for: .normal)
        self.isSelected = isSelected
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        setupCapsule()
    }
    
    private func setupCapsule() {
        if capsuleLayer == nil {
            let state = self.state
            let mLayer = CALayer()
            mLayer.masksToBounds = true
            mLayer.backgroundColor = backgroundColor(for: state)?.cgColor ?? UIColor.white.cgColor
            mLayer.borderWidth = borderWidth(for: state)
            mLayer.cornerRadius = self.bounds.height / 2
            self.capsuleLayer = mLayer
            self.layer.insertSublayer(mLayer, at: 0)
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            updateCapsule(self.bounds)
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            updateCapsule(self.bounds)
        }
    }
    
    open override var isUserInteractionEnabled: Bool {
        didSet {
            updateCapsule(self.bounds)
        }
    }
    
    private func updateCapsule(_ rect: CGRect) {
        let state = isUserInteractionEnabled ? self.state : .disabled
        if let mLayer = self.capsuleLayer {
            mLayer.frame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
            mLayer.backgroundColor = backgroundColor(for: state)?.cgColor ?? UIColor.white.cgColor
            mLayer.borderWidth = borderWidth(for: state)
            mLayer.borderColor = borderColor(for: state)?.cgColor
            mLayer.cornerRadius = rect.height / 2
            
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateCapsule(self.bounds)
        if let mLayer = self.capsuleLayer {
            self.layer.insertSublayer(mLayer, at: 0)
        }
    }
    
    open func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        self.backgroundColors[state] = color
    }
    
    open func backgroundColor(for state: UIControl.State) -> UIColor? {
        return self.backgroundColors[state]
    }
    
    open func setBorderWidth(_ width: CGFloat, for state: UIControl.State) {
        self.borderWidths[state] = width
    }
    
    open func borderWidth(for state: UIControl.State) -> CGFloat {
        return self.borderWidths[state] ?? 0
    }
    
    open func setBorderColor(_ color: UIColor, for state: UIControl.State) {
        self.borderColors[state] = color
    }
    
    open func borderColor(for state: UIControl.State) -> UIColor? {
        return self.borderColors[state]
    }
}
