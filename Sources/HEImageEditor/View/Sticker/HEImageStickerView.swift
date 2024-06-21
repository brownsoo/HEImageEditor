//
//  HEImageStickerView.swift
//  HEImageEditor
//

import UIKit

class HEImageStickerView: HEBaseStickerView {
    
    static let edgeInset: CGFloat = 5
    
    private var image: UIImage
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    // Convert all states to model.
    override var state: HEImageStickerEffect {
        return HEImageStickerEffect(
            id: id,
            kind: kind,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
    
    var isMosaic: Bool {
        self.kind == .mosaic
    }
    
    deinit {
        trace()
    }
    
    convenience init(state: HEImageStickerEffect) {
        self.init(
            id: state.id,
            kind: state.kind,
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
        kind: HEImageSticker.Kind = .default,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.image = image
        super.init(
            id: id,
            kind: kind,
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
        imageView.frame = bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
    }
    
    func setImage(_ image: UIImage) {
        self.image = image
        self.imageView.image = image
    }
    
    class func constraintViewSize(image: UIImage, container: UIView) -> CGSize {
//        let scale = (container.window?.windowScene?.screen.scale ?? image.scale)
//        let startSide: CGFloat = 150 / scale // 150 pixel
//        let minSide: CGFloat = 50 / scale // 50 pixel
        let startSide: CGFloat = 150 
        let minSide: CGFloat = 50
        let whRatio = image.size.width / image.size.height
        var size: CGSize = .zero
        if whRatio >= 1 {
            let w = min(startSide, max(minSide, image.size.width))
            let h = w / whRatio
            size = CGSize(width: w, height: h)
        } else {
            let h = min(startSide, max(minSide, image.size.width))
            let w = h * whRatio
            size = CGSize(width: w, height: h)
        }
        size.width += Self.edgeInset * 2
        size.height += Self.edgeInset * 2
        return size
    }
}
