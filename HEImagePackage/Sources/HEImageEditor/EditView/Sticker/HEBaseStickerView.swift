//
//  HEBaseStickerView.swift
//  HEImageEditor
//

import UIKit
import HECommon

protocol HEStickerViewDelegate: NSObject {
    /// Called when scale or rotate or move.
    func stickerBeginOperation(_ sticker: HEBaseStickerView)
    
    /// Called during scale or rotate or move.
    func stickerOnOperation(_ sticker: HEBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called after scale or rotate or move.
    func stickerEndOperation(_ sticker: HEBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called when tap sticker.
    func stickerDidTap(_ sticker: HEBaseStickerView)
    
    func sticker(_ textSticker: HETextStickerView, editText text: String)
}

protocol HEStickerViewAdditional: NSObject {
    var gesIsEnabled: Bool { get set }
    
    func resetState()
    
    func moveToTrashbin()
    
    func addScale(_ scale: CGFloat)
}

public class HEBaseStickerView: UIView, UIGestureRecognizerDelegate {
    private enum Direction: Int {
        case up = 0
        case right = 90
        case bottom = 180
        case left = 270
    }
    
    var id: String
    
    let kind: HEImageSticker.Kind
    
    var borderWidth = 1 / UIScreen.main.scale {
        willSet {
            DispatchQueue.main.async {
                self.borderView.layer.borderWidth = newValue
            }
        }
    }
    
    var firstLayout = true
    
    let originScale: CGFloat
    
    let originAngle: CGFloat
    
    var maxGesScale: CGFloat
    var minGesScale: CGFloat
    
    var originTransform: CGAffineTransform = .identity
    
    var totalTranslationPoint: CGPoint = .zero
    
    var gesTranslationPoint: CGPoint = .zero
    
    var gesRotation: CGFloat = 0
    
    var gesScale: CGFloat = 1
    
    var onOperation = false
    
    var gesIsEnabled = true
    
    var originFrame: CGRect
    
    lazy var tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    
    lazy var pinchGes: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinch.delegate = self
        return pinch
    }()
    
    lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    var state: HEStickerEffect {
        fatalError()
    }
    
    var borderView: UIView {
        return self
    }
    
    var contentView: UIView {
        return self
    }
    
    var visibleFrame: CGRect
    
    weak var delegate: HEStickerViewDelegate?
    
    class func initWithState(_ effect: HEStickerEffect) -> HEBaseStickerView? {
        if let state = effect as? HETextStickerEffect {
            return HETextStickerView(state: state)
        } else if let state = effect as? HEImageStickerEffect {
            return HEImageStickerView(state: state)
        } else {
            return nil
        }
    }
    
    init(
        id: String = UUID().uuidString,
        kind: HEImageSticker.Kind,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        
        // 최대 스케일 설정 - 최대 사이즈 512 , 기본 사이즈 150
        self.maxGesScale = CGFloat(512.0 / 150.0)
        // 최소 스케일 설정 - 최소 사이즈 50 , 기본 사이즈 150
        self.minGesScale = CGFloat(50.0 / 150.0)
        
        self.visibleFrame = originFrame
        super.init(frame: .zero)
        
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        
        self.borderWidth = 1 / gesScale / originScale
        
        if showBorder {
            self.showBorder()
        } else {
            self.hideBorder()
        }
        
        addGestureRecognizer(tapGes)
        addGestureRecognizer(pinchGes)
        
        let rotationGes = UIRotationGestureRecognizer(target: self, action: #selector(rotationAction(_:)))
        rotationGes.delegate = self
        addGestureRecognizer(rotationGes)
        
        addGestureRecognizer(panGes)
        tapGes.require(toFail: panGes)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard firstLayout else {
            return
        }
        
        // Rotate must be first when first layout.
        transform = transform.rotated(by: originAngle.he.toPi)
        
        if totalTranslationPoint != .zero {
            let direction = direction(for: originAngle)
            if direction == .right {
                transform = transform.translatedBy(x: totalTranslationPoint.y, y: -totalTranslationPoint.x)
            } else if direction == .bottom {
                transform = transform.translatedBy(x: -totalTranslationPoint.x, y: -totalTranslationPoint.y)
            } else if direction == .left {
                transform = transform.translatedBy(x: -totalTranslationPoint.y, y: totalTranslationPoint.x)
            } else {
                transform = transform.translatedBy(x: totalTranslationPoint.x, y: totalTranslationPoint.y)
            }
        }
        
        transform = transform.scaledBy(x: originScale, y: originScale)
        
        originTransform = transform
        
        if gesScale != 1 {
            transform = transform.scaledBy(x: gesScale, y: gesScale)
        }
        if gesRotation != 0 {
            transform = transform.rotated(by: gesRotation)
        }
        
        firstLayout = false
        setupUIFrameWhenFirstLayout()
    }
    
    func setupUIFrameWhenFirstLayout() {}
    
    private func direction(for angle: CGFloat) -> HEBaseStickerView.Direction {
        let angle = ((Int(angle) % 360) + 360) % 360
        return HEBaseStickerView.Direction(rawValue: angle) ?? .up
    }
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        showBorder()
        delegate?.stickerDidTap(self)
    }
    
    @objc func pinchAction(_ ges: UIPinchGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let scale = max(minGesScale, min(maxGesScale, gesScale * ges.scale))
        ges.scale = 1
        
        var scaleChanged = false
        if scale != gesScale {
            gesScale = scale
            scaleChanged = true
        }
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            if scaleChanged {
                updateTransform()
            }
        } else if ges.state == .ended || ges.state == .cancelled {
            // 드래그가 있는 경우 panAction에서 setOperation(false)이 실행됩니다.
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func rotationAction(_ ges: UIRotationGestureRecognizer) {
        guard gesIsEnabled else { return }
        guard kind != .mosaic else { return }
        
        gesRotation += ges.rotation
        ges.rotation = 0
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled || ges.state == .failed {
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func panAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let point = ges.translation(in: superview)
        gesTranslationPoint = CGPoint(x: point.x / originScale, y: point.y / originScale)
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled || ges.state == .failed || self.onOperation {
            totalTranslationPoint.x += point.x
            totalTranslationPoint.y += point.y
            setOperation(false)
            let direction = direction(for: originAngle)
            if direction == .right {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
            } else if direction == .bottom {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
            } else if direction == .left {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
            } else {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
            }
            gesTranslationPoint = .zero
        }
    }
    
    func setOperation(_ isOn: Bool) {
        if isOn, !onOperation {
            onOperation = true
            showBorder()
            delegate?.stickerBeginOperation(self)
        } else if !isOn, onOperation {
            onOperation = false
            delegate?.stickerEndOperation(self, panGes: panGes)
        }
    }
    
    func updateTransform() {
        var transform = originTransform
        
        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
        } else if direction == .left {
            transform = transform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
        } else {
            transform = transform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
        }
        // Scale must after translate.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Rotate must after scale.
        transform = transform.rotated(by: gesRotation)
        self.transform = transform
        
        self.borderWidth = 1 / gesScale / originScale
        
        delegate?.stickerOnOperation(self, panGes: panGes)
    }
    
    private(set) var isBordered = false
    
    @objc
    func hideBorder() {
        isBordered = false
        borderView.layer.borderColor = UIColor.clear.cgColor
    }
    
    @objc
    func showBorder() {
        isBordered = true
        borderWidth = 1 / gesScale / originScale
        borderView.layer.borderColor = UIColor.white.cgColor
    }
    
    // MARK: UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension HEBaseStickerView: HEStickerViewAdditional {
    func resetState() {
        onOperation = false
        hideBorder()
    }
    
    func moveToTrashbin() {
        moveToTrashbin(withHaptic: true)
    }
    
    /// 제거
    func moveToTrashbin(withHaptic haptic: Bool) {
        removeFromSuperview()
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)            
        }
    }
    
    func addScale(_ scale: CGFloat) {
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        
        var origin = frame.origin
        origin.x *= scale
        origin.y *= scale
        
        let newSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        let newOrigin = CGPoint(x: frame.minX + (frame.width - newSize.width) / 2, y: frame.minY + (frame.height - newSize.height) / 2)
        let diffX: CGFloat = (origin.x - newOrigin.x)
        let diffY: CGFloat = (origin.y - newOrigin.y)
        
        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: diffY, y: -diffX)
            originTransform = originTransform.translatedBy(x: diffY / originScale, y: -diffX / originScale)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -diffX, y: -diffY)
            originTransform = originTransform.translatedBy(x: -diffX / originScale, y: -diffY / originScale)
        } else if direction == .left {
            transform = transform.translatedBy(x: -diffY, y: diffX)
            originTransform = originTransform.translatedBy(x: -diffY / originScale, y: diffX / originScale)
        } else {
            transform = transform.translatedBy(x: diffX, y: diffY)
            originTransform = originTransform.translatedBy(x: diffX / originScale, y: diffY / originScale)
        }
        totalTranslationPoint.x += diffX
        totalTranslationPoint.y += diffY
        
        transform = transform.scaledBy(x: scale, y: scale)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        
        gesScale *= scale
        maxGesScale *= scale
        minGesScale *= scale
    }
}
