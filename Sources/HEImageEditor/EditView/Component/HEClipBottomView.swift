//
//  HEClipBottomView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/7/24.
//

import Foundation
import UIKit

/// 자르기 화면 하단에 놓을 수 있는 작업뷰 예시
///
/// - 미사용 상태
final public class HEClipBottomView: UIView {
    
    public static let estimateHeight: CGFloat = 72
    
    public var cancelClickListener: (() -> Void)?
    public var revertClickListener: (() -> Void)?
    public var doneClickListener: (() -> Void)?
    
    private lazy var shadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let color1 = UIColor.black.withAlphaComponent(0.15).cgColor
        let color2 = UIColor.black.withAlphaComponent(0.35).cgColor
        layer.colors = [color1, color2]
        layer.locations = [0, 1]
        return layer
    }()
    
    private lazy var lineView = UIView()
    private lazy var cancelBtn = HEEnlargeButton(type: .custom)
    private lazy var revertBtn = HEEnlargeButton(type: .custom)
    private lazy var doneBtn = HEEnlargeButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        self.layer.addSublayer(shadowLayer)
        
        let buttonStack = UIStackView(arrangedSubviews: [
            cancelBtn, revertBtn, doneBtn
        ])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .equalCentering
        self.addSubview(buttonStack)
        
        cancelBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelBtn.adjustsImageWhenHighlighted = false
        cancelBtn.enlargeInset = 20
        cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        
        revertBtn.setTitle(localLanguageTextValue(.revert), for: .normal)
        revertBtn.enlargeInset = 20
        revertBtn.titleLabel?.font = .systemFont(ofSize: 17)
        revertBtn.addTarget(self, action: #selector(revertBtnClick), for: .touchUpInside)
        
        doneBtn.setImage(UIImage(systemName: "checkmark"), for: .normal)
        doneBtn.adjustsImageWhenHighlighted = false
        doneBtn.enlargeInset = 20
        doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        
        lineView.backgroundColor = .he.rgba(240, 240, 240)
        self.addSubview(lineView)
        
        lineView.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            buttonStack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30).withPriority(.defaultHigh),
            buttonStack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30).withPriority(.defaultHigh),
            buttonStack.topAnchor.constraint(equalTo: self.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: self.bottomAnchor).withPriority(.defaultHigh)
        ])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        shadowLayer.frame = self.bounds
    }
    
    @objc
    private func cancelBtnClick() {
        cancelClickListener?()
    }
    
    @objc
    private func revertBtnClick() {
        revertClickListener?()
    }
    
    @objc
    private func doneBtnClick() {
        doneClickListener?()
    }
}
