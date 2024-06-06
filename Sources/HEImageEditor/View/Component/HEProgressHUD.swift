//
//  ZLProgressHUD.swift
//  HEImageEditor
//

import UIKit

public class HEProgressHUD: UIView {
    private let style: HEProgressHUD.HUDStyle
    
    private lazy var loadingView = UIImageView(image: style.icon)
    
    deinit {
        trace("ZLProgressHUD deinit")
    }
    
    @objc public init(style: HEProgressHUD.HUDStyle) {
        self.style = style
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 135))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = style.bgColor
        view.clipsToBounds = true
        view.center = center
        
        if let effectStyle = style.blurEffectStyle {
            let effect = UIBlurEffect(style: effectStyle)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.bounds
            view.addSubview(effectView)
        }
        
        loadingView.frame = CGRect(x: 135 / 2 - 22, y: 25, width: 44, height: 44)
        view.addSubview(loadingView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 85, width: view.bounds.width, height: 30))
        label.textAlignment = .center
        label.textColor = style.textColor
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = localLanguageTextValue(.hudProcessing)
        view.addSubview(label)
        
        addSubview(view)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        loadingView.layer.add(animation, forKey: nil)
    }
    
    @objc public func show(in view: UIView? = nil) {
        let parentView = view ?? UIApplication.shared.findKeyWindow()
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(in: parentView)
            }
            return
        }
        
        startAnimation()
        parentView?.addSubview(self)
    }
    
    @objc public func hide() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.hide()
            }
            return
        }
        
        loadingView.layer.removeAllAnimations()
        removeFromSuperview()
    }
}

public extension HEProgressHUD {
    @objc enum HUDStyle: Int {
        case light
        case lightBlur
        case dark
        case darkBlur
        
        var bgColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return .darkGray
            case .lightBlur:
                return UIColor.white.withAlphaComponent(0.8)
            case .darkBlur:
                return UIColor.darkGray.withAlphaComponent(0.8)
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .light, .lightBlur:
                return .he.getImage("zl_loading_dark")
            case .dark, .darkBlur:
                return .he.getImage("zl_loading_light")
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light, .lightBlur:
                return .black
            case .dark, .darkBlur:
                return .white
            }
        }
        
        var blurEffectStyle: UIBlurEffect.Style? {
            switch self {
            case .light, .dark:
                return nil
            case .lightBlur:
                return .extraLight
            case .darkBlur:
                return .dark
            }
        }
    }
}
