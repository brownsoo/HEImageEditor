//
//  HETopConfirmBarView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/13/24.
//

import UIKit

class HETopConfirmBarView: UIView {
    
    private var cancelButton: UIButton!
    private var confirmButton: UIButton!
    
    var cancelClickCallback: (() -> Void)?
    var confirmClickCallback: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        cancelButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        cancelButton.setImage(.he.getImage("icClose24")?.withRenderingMode(.alwaysOriginal), for: .normal)
        confirmButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        confirmButton.setImage(.he.getImage("icCheck")?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        self.addSubview(cancelButton)
        self.addSubview(confirmButton)
        
        self.backgroundColor = .yellow.withAlphaComponent(0.2)
        
        cancelButton.addAction(.init(handler: { [weak self] _ in self?.cancelClickCallback?() }), for: .touchUpInside)
        confirmButton.addAction(.init(handler: { [weak self] _ in self?.confirmClickCallback?() }), for: .touchUpInside)
        
        self.backgroundColor = .yellow.withAlphaComponent(0.2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let top = (self.bounds.height - CGFloat(44)) / 2
        cancelButton.frame = CGRect(x: 0, y: top, width: 44, height: 44)
        confirmButton.frame = CGRect(x: self.bounds.width - CGFloat(44),
                                     y: top,
                                     width: 44,
                                     height: 44)
        
    }
}
