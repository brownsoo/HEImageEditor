//
//  HEStickerEffect.swift
//  HEImageEditor
//

import UIKit

public class HEStickerEffect: NSObject {
    let id: String
    let kind: HEImageSticker.Kind
    let image: UIImage
    let originScale: CGFloat
    let originAngle: CGFloat
    let originFrame: CGRect
    let gesScale: CGFloat
    let gesRotation: CGFloat
    let totalTranslationPoint: CGPoint
    let visibleFrame: CGRect
    
    var isTextSticker: Bool {
        false
    }
    
    public init(
        id: String,
        kind: HEImageSticker.Kind,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint,
        visibleFrame: CGRect
    ) {
        self.id = id
        self.kind = kind
        self.image = image
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        self.visibleFrame = visibleFrame
        super.init()
    }
}

public class HEImageStickerEffect: HEStickerEffect {
}

public class HETextStickerEffect: HEStickerEffect {
    let text: String
    let textColor: UIColor
    let fillColor: UIColor
    let font: UIFont?
    
    override var isTextSticker: Bool {
        true
    }
    
    public init(
        id: String,
        text: String,
        textColor: UIColor,
        fillColor: UIColor,
        font: UIFont?,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint,
        visibleFrame: CGRect
    ) {
        self.text = text
        self.textColor = textColor
        self.fillColor = fillColor
        self.font = font
        super.init(
            id: id,
            kind: .default,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            visibleFrame: visibleFrame
        )
    }
}

