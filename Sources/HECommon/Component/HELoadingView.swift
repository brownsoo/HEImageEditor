//
//  HELoadingView.swift
//  HECommon
//
//  Created by 브라운수 on 6/13/24.
//

import UIKit

public class HELoadingView: UIView {
    public override var intrinsicContentSize: CGSize {
        CGSize(width: 78, height: 78)
    }
    
    private var requiredLayout = true
    private var arcShapeLayer: CAShapeLayer?
    
    public var isShowing: Bool {
        superview != nil
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview == nil {
            
        } else {
            
        }
    }
    
    public func show(inCenterOf parent: UIView) {
        self.backgroundColor = .black.withAlphaComponent(0.72)
        self.layer.cornerRadius = 12
        self.frame = CGRect(x: (parent.bounds.width - 78) / 2,
                            y: (parent.bounds.height - 78) / 2,
                            width: 78,
                            height: 78)
        
        parent.addSubview(self)
        requiredLayout = true
        setNeedsLayout()
    }
    
    public func hide() {
        arcShapeLayer?.removeAllAnimations()
        
        removeFromSuperview()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard requiredLayout else {
            return
        }
        requiredLayout = false
        self.arcShapeLayer?.removeFromSuperlayer()
        
        let radius = bounds.width * CGFloat(46.0 / 78.0) / 2
        let center = CGPoint(x: bounds.width / 2, y: bounds.width / 2)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 1.25, clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(shapeLayer)
        shapeLayer.add(rotationAnimation, forKey: "transform.rotation")
        self.arcShapeLayer = shapeLayer
    }
    
    private let rotationAnimation: CAAnimation = {
        let ani = CABasicAnimation(keyPath: "transform.rotation")
        ani.fromValue = 0
        ani.toValue = Double.pi * 2
        ani.duration = 0.34
        ani.repeatCount = MAXFLOAT
        return ani
    }()
}
