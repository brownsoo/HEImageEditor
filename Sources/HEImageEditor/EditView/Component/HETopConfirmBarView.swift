//
//  HETopConfirmBarView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/13/24.
//

import UIKit

class HETopConfirmBarView: HETopBarView {
    
    private lazy var cancelButton = UIButton()
    private lazy var confirmButton = UIButton()
    private let contentView = UIView()
    var cancelClickCallback: (() -> Void)?
    var confirmClickCallback: (() -> Void)?
    
    override public func setupUI() {
        super.setupUI()
        let cancelIcon = UIImage.he.getImage("icClose24") ?? UIImage(systemName: "xmark")
        cancelButton.setImage(cancelIcon, for: .normal)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let checkIcon = UIImage.he.getImage("icCheck") ?? UIImage(systemName: "checkmark")
        confirmButton.setImage(checkIcon, for: .normal)
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        addLeadingView(cancelButton)
        addTrailingView(confirmButton)
        
        cancelButton.addAction(.init(handler: { [weak self] _ in self?.cancelClickCallback?() }), for: .touchUpInside)
        confirmButton.addAction(.init(handler: { [weak self] _ in self?.confirmClickCallback?() }), for: .touchUpInside)
    }
}
