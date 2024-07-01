//
//  HETextStickerView.swift
//  HEImageEditor
//

import UIKit

class HETextStickerView: HEBaseStickerView {
    static let fontSize: CGFloat = 23
    
    private static let edgeInset: CGFloat = 10
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    var text: String
    var textColor: UIColor
    var fillColor: UIColor
    var font: UIFont?
    
    var image: UIImage {
        didSet {
            imageView.image = image
        }
    }
    
    // Convert all states to model.
    override var state: HETextStickerEffect {
        return HETextStickerEffect(
            id: id,
            text: text,
            textColor: textColor,
            fillColor: fillColor,
            font: font,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
    
    deinit {
        trace()
    }
    
    convenience init(state: HETextStickerEffect) {
        self.init(
            id: state.id,
            text: state.text,
            textColor: state.textColor,
            fillColor: state.fillColor,
            font: state.font,
            image: state.image,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            showBorder: false
        )
    }
    
    init(
        id: String = UUID().uuidString,
        text: String,
        textColor: UIColor,
        fillColor: UIColor,
        font: UIFont? = nil,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.text = text
        self.textColor = textColor
        self.fillColor = fillColor
        self.font = font
        self.image = image
        super.init(
            id: id,
            kind: .default,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            showBorder: showBorder
        )
        
        borderView.addSubview(imageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        imageView.frame = borderView.bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
    }
    
    override func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        if let timer = timer, timer.isValid {
            delegate?.sticker(self, editText: text)
        } else {
            super.tapAction(ges)
        }
    }
    
    func changeSize(to newSize: CGSize) {
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        transform = transform.rotated(by: -originAngle.he.toPi)
        
        // Recalculate current frame.
        let center = CGPoint(x: self.frame.midX, y: self.frame.midY)
        var frame = self.frame
        frame.origin.x = center.x - newSize.width / 2
        frame.origin.y = center.y - newSize.height / 2
        frame.size = newSize
        self.frame = frame
        
        let oc = CGPoint(x: originFrame.midX, y: originFrame.midY)
        var of = originFrame
        of.origin.x = oc.x - newSize.width / 2
        of.origin.y = oc.y - newSize.height / 2
        of.size = newSize
        originFrame = of
        
        imageView.frame = borderView.bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        transform = transform.rotated(by: originAngle.he.toPi)
    }
    
    class func calculateSize(image: UIImage) -> CGSize {
        var size = image.size
        size.width += Self.edgeInset * 2
        size.height += Self.edgeInset * 2
        return size
    }
}
