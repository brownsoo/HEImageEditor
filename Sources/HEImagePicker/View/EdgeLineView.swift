//
//  TopEdgeLineView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/24/24.
//

import UIKit

class EdgeLineView: UIView {
    
    struct LineEdges: OptionSet {
        
        let rawValue: Int
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let leading  = LineEdges(rawValue: 1 << 0)
        static let trailing = LineEdges(rawValue: 1 << 1)
        static let top      = LineEdges(rawValue: 1 << 2)
        static let bottom   = LineEdges(rawValue: 1 << 3)
        
        static let all: LineEdges = [.leading, .trailing, .top, .bottom]
        static let horizontal: LineEdges = [.leading, .trailing]
        static let vertical: LineEdges = [.top, .bottom]
        
    }
    
    var edges: LineEdges = .top
    private var boundLayer: CALayer?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CG 컨텍스트 스트로크 색(.separator)은 동적 컬러라, 모드 전환 시 다시 그려야 한다.
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if !edges.isEmpty, let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.separator.cgColor)
            context.setLineWidth(1)
                context.beginPath()
            
            if edges.contains(.top) {
                context.move(to: rect.origin)
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.closePath()
                context.strokePath()
            }
            
            if edges.contains(.leading) {
                context.move(to: rect.origin)
                context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                context.closePath()
                context.strokePath()
            }
            
            if edges.contains(.trailing) {
                context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                context.closePath()
                context.strokePath()
            }
            
            if edges.contains(.bottom) {
                context.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                context.closePath()
                context.strokePath()
            }
        }
    }
    
}
