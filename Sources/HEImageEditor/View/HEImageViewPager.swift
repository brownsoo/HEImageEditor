//
//  HEImageViewPager.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit

public protocol HEImageViewPager {
//    var imageViews: [HEEditImageView] { get }
    var selectedImage: HEImage? { get }
    var currentPage: Int { get set }
    var pageCount: Int { get }
    
//    func addImageView(imageView: HEEditImageView)
//    func removeImageView(imageView: HEEditImageView)
//    func selectImageView(imageView: HEEditImageView)
//    func nextPage()
//    func prevPage()
}

public protocol HEImageViewPagerDataSource: AnyObject {
    func numberOfImageViews(in pager: HEImageViewPager) -> Int
    func imageViewPager(_ pager: HEImageViewPager, imageAt Index: Int) -> HEImage
    func imageViewPager(_ pager: HEImageViewPager, imageForId id: String) -> HEImage
}

public class HEImageViewPagerController: UIViewController, HEImageViewPager {
    
    public weak var imageDataSource: HEImageViewPagerDataSource?
    
    public var selectedImage: HEImage?
    
    public var currentPage: Int = 0 {
        didSet {
            
        }
    }
    
    public var pageCount: Int {
        imageDataSource?.numberOfImageViews(in: self) ?? 0
    }
    
    private lazy var indexLabel: UILabel = {
       let lb = UILabel()
        lb.text = "0/0"
        lb.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lb.textColor = .he.rgba(246, 246, 246)
        return lb
    }()
    
    private var resetToastView: UIView!
    private var collView: UICollectionView!
    private var bottomToolView: HEEditToolView!
    private var bottomToolViewHeight: CGFloat = 0
    private var topBarView: HETopBarView!
    private var topBarViewHeight: CGFloat = 0
    private var shouldLayout = true
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }
        shouldLayout = false
        trace("pager didLayout")
        
        let insets = self.view.safeAreaInsets
        collView.frame = view.bounds
        topBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top + topBarViewHeight)
        
        bottomToolView.frame = CGRect(x: 0,
                                      y: view.frame.height - bottomToolViewHeight - insets.bottom,
                                      width: view.bounds.width,
                                      height: bottomToolViewHeight + insets.bottom)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        topBarView.show()
    }
    
    private func showAiStickerToastIfNeed(stickerTrayFrame: CGRect) {
        guard resetToastView.superview == nil else { return }
        view.addSubview(resetToastView)
        resetToastView.also { it in
            it.alpha = 0
            it.sizeToFit()
            it.frame = CGRect(x: (view.bounds.width - it.bounds.width) / 2,
                              y: stickerTrayFrame.minY - it.bounds.height,
                              width: it.bounds.width,
                              height: it.bounds.height)
            let tp = CGPoint(x: (view.bounds.width - it.bounds.width) / 2, y: stickerTrayFrame.minY - it.bounds.height - 16)
            UIView.animate(withDuration: 0.24, delay: 0.2, options: [.curveEaseOut], animations: {
                it.alpha = 1
                it.frame.origin = tp
            }, completion: { _ in
                self.perform(#selector(self.hideAiStickerToast), with: nil, afterDelay: 3)
            })
        }
    }
    
    @objc private func hideAiStickerToast() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideAiStickerToast), object: nil)
        guard resetToastView.superview != nil else {
            return
        }
        UIView.animate(withDuration: 0.24, delay: 0, animations: {
            self.resetToastView.alpha = 0
        }, completion: { _ in
            self.resetToastView.removeFromSuperview()
        })
    }
    
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
    
    func makeBottomToolView() -> (HEEditToolView, CGFloat) {
        // 기본 툴바
        var ts = HEConfiguration.default().tools
        if ts.contains(.imageSticker), HEConfiguration.default().imageStickerTray == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        let toolbar = HEEditImageBottomToolView(tools: ts)
        toolbar.toolSelectListener = { [weak self] type in
//            guard let editView else { return }
//            if editView.isImageEditing {
//                editView.stopCurrentEditing()
//                return
//            }
//            switch type {
//            case .draw:
//                editView.startDrawing()
//            case .clip:
//                editView.startClipping()
//            case .imageSticker:
//                editView.startImageSticker()
//            case .textSticker:
//                editView.startTextSticker()
//            case .mosaicDraw:
//                editView.startMosaicDrawing()
//            case .filter:
//                editView.startFiltering()
//            case .adjust:
//                editView.startAdjusting()
//            }
        }
        return (toolbar, 76)
    }
}

extension HEImageViewPagerController {
    
    private func setupUI() {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.backgroundColor = .clear
        coll.showsHorizontalScrollIndicator = false
        HEImageViewPageCell.he.register(coll)
        coll.dataSource = self
        coll.delegate = self
        view.addSubview(coll)
        self.collView = coll
        
        let toolBuilder = makeBottomToolView()
        bottomToolView = toolBuilder.0
        bottomToolViewHeight = toolBuilder.1
        view.addSubview(bottomToolView)
        
        let topBuilder = makeTopBarView()
        topBarView = topBuilder.0
        topBarViewHeight = topBuilder.1
        view.addSubview(topBarView)
        topBarView.hide(animate: false)
        
        let bt = UIButton()
        bt.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        bt.layer.cornerRadius = 16
        let icon = UIImage.he.getImage("ic_edit_refresh") ?? UIImage(systemName: "arrow.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .small))?.withTintColor(.white)
        bt.setImage(icon, for: .normal)
        bt.setTitle("원본으로 초기화", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 14)
        bt.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        bt.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16 + 2)
        bt.adjustsImageWhenHighlighted = false
        resetToastView = bt
    }
    
}

extension HEImageViewPagerController: UICollectionViewDelegate {
    
}

extension HEImageViewPagerController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEImageViewPageCell.he.identifier, for: indexPath)
        return cell
    }
    
    
}

class HEImageViewPageCell: UICollectionViewCell {
    
    private var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.widthAnchor.constraint(equalToConstant: 40),
                it.heightAnchor.constraint(equalToConstant: 40),
                it.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                it.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
