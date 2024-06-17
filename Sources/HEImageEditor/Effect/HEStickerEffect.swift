//
//  HEStickerEffect.swift
//  HEImageEditor
//

import UIKit

public class HEStickerEffect: NSObject {
    let id: String
    let image: UIImage
    let originScale: CGFloat
    let originAngle: CGFloat
    let originFrame: CGRect
    let gesScale: CGFloat
    let gesRotation: CGFloat
    let totalTranslationPoint: CGPoint
    
    public init(
        id: String,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.id = id
        self.image = image
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        super.init()
    }
}

//public class HEMosaicStickerEffect: HEStickerEffect {
//    public init(
//        id: String,
//        originScale: CGFloat,
//        originAngle: CGFloat,
//        originFrame: CGRect,
//        gesScale: CGFloat,
//        gesRotation: CGFloat,
//        totalTranslationPoint: CGPoint
//    ) {
//        super.init(
//            id: id,
//            image: UIImage(),
//            originScale: originScale,
//            originAngle: originAngle,
//            originFrame: originFrame,
//            gesScale: gesScale,
//            gesRotation: gesRotation,
//            totalTranslationPoint: totalTranslationPoint
//        )
//    }
//}

public class HEImageStickerEffect: HEStickerEffect {
}

public class HETextStickerEffect: HEStickerEffect {
    let text: String
    let textColor: UIColor
    let font: UIFont?
    let style: HEInputTextStyle
    
    public init(
        id: String,
        text: String,
        textColor: UIColor,
        font: UIFont?,
        style: HEInputTextStyle,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.style = style
        super.init(
            id: id,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
}

