//
//  HEImageViewPager.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit

public protocol HEImageViewPager {
    var effectImageViews: [HEEditImageView] { get }
    var selectedEffectImageView: HEEditImageView? { get }
    var currentPage: Int { get set }
    var pageCount: Int { get }
    
    func addEffectImageView(imageView: HEEditImageView)
    func removeEffectImageView(imageView: HEEditImageView)
    func selectEffectImageView(imageView: HEEditImageView)
    func nextPage()
    func prevPage()
}


public class HEImageViewPagerController: UIViewController {
    
    
    private lazy var indexLabel: UILabel = {
       let lb = UILabel()
        lb.text = "0/0"
        lb.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lb.textColor = .he.rgba(246, 246, 246)
        return lb
    }()
    
    @objc
    private func didClickCancel() {
        
    }
    
    @objc
    private func didConfirmClick() {
        
    }
    
    func makeTopBarView() -> (HETopBarView, CGFloat) {
        let topbar = HETopBarView()
        let cancelButton = UIButton()
        cancelButton.also { it in
            let icon = UIImage.he.getImage("ic_arrow_right") ?? UIImage(systemName: "chevron.left")
            it.setImage(icon, for: .normal)
            it.frame = CGRect(origin: .zero, size: .init(width: 48, height: 48))
        }
        topbar.addLeadingView(cancelButton)
        
        let confirmButton = UIButton()
        confirmButton.also { it in
            it.setTitle(localLanguageTextValue(.done), for: .normal)
            it.setTitleColor(.he.rgba(246, 246, 246), for: .normal)
            it.setTitleColor(.lightGray, for: .disabled)
            it.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            it.contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
            it.setContentHuggingPriority(.required, for: .horizontal)
            it.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        topbar.addTrailingView(confirmButton)
        topbar.addCenterView(indexLabel)
        
        cancelButton.addAction(.init(handler: { [weak self] _ in self?.didClickCancel() }), for: .touchUpInside)
        confirmButton.addAction(.init(handler: { [weak self] _ in self?.didConfirmClick() }), for: .touchUpInside)
        
        return (topbar, 44)
    }
}
