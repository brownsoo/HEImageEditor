//
//  HETopConfirmBarView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/13/24.
//

import UIKit

class HETopConfirmBarView: UIView {
    
    private lazy var cancelButton = UIButton()
    private lazy var confirmButton = UIButton()
    private let contentView = UIView()
    var cancelClickCallback: (() -> Void)?
    var confirmClickCallback: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func show(animate: Bool = true) {
        let origin = CGPoint(x: 0, y: bounds.height - 48)
        let target = CGRect(origin: origin, size: CGSize(width: bounds.width, height: 48))
        if animate {
            self.isHidden = false
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseOut], animations: {
                self.alpha = 1
                self.contentView.frame = target
            })
        } else {
            self.isHidden = false
            self.alpha = 1
            self.contentView.frame = target
        }
    }
    
    func hide(animate: Bool = true) {
        let origin = CGPoint(x: 0, y: bounds.height - 48 - 12)
        let target = CGRect(origin: origin, size: CGSize(width: bounds.width, height: 48))
        if animate {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear], animations: {
                self.alpha = 0
                self.contentView.frame = target
            }) { _ in
                self.isHidden = true
            }
        } else {
            self.alpha = 0
            self.isHidden = true
            self.contentView.frame = target
        }
    }
    
    private func setupUI() {
        let cancelIcon = UIImage.he.getImage("icClose24") ?? UIImage(systemName: "xmark")
        cancelButton.setImage(cancelIcon, for: .normal)
        let checkIcon = UIImage.he.getImage("icCheck") ?? UIImage(systemName: "checkmark")
        confirmButton.setImage(checkIcon, for: .normal)
        
        contentView.addSubview(cancelButton)
        contentView.addSubview(confirmButton)
        
        self.addSubview(contentView)
        
        cancelButton.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.widthAnchor.constraint(equalTo: contentView.heightAnchor),
                it.heightAnchor.constraint(equalTo: contentView.heightAnchor),
                it.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                it.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ])
        }
        
        confirmButton.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.widthAnchor.constraint(equalTo: contentView.heightAnchor),
                it.heightAnchor.constraint(equalTo: contentView.heightAnchor),
                it.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                it.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }
        
        cancelButton.addAction(.init(handler: { [weak self] _ in self?.cancelClickCallback?() }), for: .touchUpInside)
        confirmButton.addAction(.init(handler: { [weak self] _ in self?.confirmClickCallback?() }), for: .touchUpInside)
        
        
        self.backgroundColor = .yellow.withAlphaComponent(0.2)
        
    }
}
