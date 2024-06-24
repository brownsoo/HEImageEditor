//
//  HEImageViewPager.swift
//  HiImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import Combine

public protocol HEImageViewPager {
//    var imageViews: [HEEditImageView] { get }
    var currentImage: HEImage? { get }
    var currentIndex: Int? { get }
//    var pageCount: Int { get }
    
//    func addImageView(imageView: HEEditImageView)
//    func removeImageView(imageView: HEEditImageView)
//    func selectImageView(imageView: HEEditImageView)
//    func nextPage()
//    func prevPage()
}

public protocol HEImageViewPagerDelegate: AnyObject {
    
}

public class HEImageViewPagerController: UIViewController, HEImageViewPager {
    
    public weak var delegate: HEImageViewPagerDelegate?
    public weak var stickerDataSource: HEImageStickerTrayViewDataSource?
    
    public weak var imageStore: HEImageDataStore!
    public weak var imageCache: HEImageCache!
    
    public private(set) var currentImage: HEImage?
    public private(set) var currentIndex: Int?
    
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
    private var cancellables = Set<AnyCancellable>()
    
    public init(imageStore: HEImageDataStore,
                imageCache: HEImageCache,
                stickerDataSource: HEImageStickerTrayViewDataSource?) {
        self.imageStore = imageStore
        self.imageCache = imageCache
        self.stickerDataSource = stickerDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    private func showResetToastIfNeed() {
        guard resetToastView.superview == nil else { return }
        view.addSubview(resetToastView)
        resetToastView.also { it in
            it.alpha = 0
            it.sizeToFit()
            it.frame = CGRect(x: (view.bounds.width - it.bounds.width) / 2,
                              y: bottomToolView.frame.minY - it.bounds.height - 14,
                              width: it.bounds.width,
                              height: it.bounds.height)
            let tp = CGPoint(x: (view.bounds.width - it.bounds.width) / 2, y: bottomToolView.frame.minY - it.bounds.height - 24)
            UIView.animate(withDuration: 0.24, delay: 0.2, options: [.curveEaseOut], animations: {
                it.alpha = 1
                it.frame.origin = tp
            })
        }
    }
    
    @objc private func hideResetToast() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideResetToast), object: nil)
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
        // TODO: - 
        if let nc = self.navigationController, nc.viewControllers.count > 1 {
            nc.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc
    private func didConfirmClick() {
        // TODO: -
    }
    
    @objc
    private func clickOnResetToast() {
        self.perform(#selector(self.hideResetToast), with: nil, afterDelay: 0.2)
        // TODO: -
        if let currentIndex, let hei = imageStore.getHEImage(at: currentIndex) {
            Task {
                hei.setEditModel(nil)
                await imageCache.clearCached(forHei: hei, includeOrigin: false)
                collView.reloadItems(at: [IndexPath(row: currentIndex, section: 0)])
            }
        }
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
            if let self, let currentImage {
                self.startEditImage(hei: currentImage, tool: type)
            }
        }
        return (toolbar, 76)
    }
    
    private func setupHEConfiguration() {
        let stickerTray = HEImageStickerTrayView()
        stickerTray.dataSource = self.stickerDataSource
        HEConfiguration.default()
            .clipRatios([.origin, .custom, .wh1x1])
            .imageStickerTray(stickerTray)
    }
    
    private func startEditImage(hei: HEImage, tool: HEConfiguration.EditTool?) {
        let topBuilder: HEEditImageTopToolViewBuilder = { [weak self] _ in
            return self?.makeTopBarView()
        }
        let bottomBuilder: HEEditImageBottomToolViewBuilder = { [weak self] _ in
            return self?.makeBottomToolView()
        }
        Task { @MainActor in
            do {
                let image = try await self.imageCache.editImage(forHei: hei).value
                let editModel = hei.editModel
                setupHEConfiguration()
                
                let vc = HEEditImageViewController(image: image, editModel: editModel, topToolViewBuilder: topBuilder, bottomToolViewBuilder: bottomBuilder)
                vc.delegate = self
                vc.editId = hei.id
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: false)
            } catch {
                woops(error)
            }
        }
        .store(in: &cancellables)
    }
}

extension HEImageViewPagerController: HEEditImageViewControllerDelegate {
    public func didFinishEditImage(resultImage: UIImage, editId: String?, editModel: HEEditImageModel?) {
        // TODO: 편집 데이터 교체
        guard let editId, let hei = imageStore.getHEImage(forId: editId) else {
            return
        }
        Task {
            hei.setEditModel(editModel)
            do {
                let fileUrl = try await imageCache.cacheEditImage(uiImage: resultImage, forHei: hei).value
                trace(fileUrl)
                let thumbUrl = try await imageCache.cacheThumbnailImage(uiImage: resultImage, forHei: hei).value
                trace(thumbUrl)
            } catch {
                woops(error)
            }
            
            if let currentIndex, currentIndex < imageStore.numberOfImages() {
                collView.reloadItems(at: [IndexPath(row: currentIndex, section: 0)])
            }
        }
    }
    
    
}


extension HEImageViewPagerController {
    
    private func setupUI() {
        
        view.backgroundColor = .blue
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.backgroundColor = .clear
        coll.showsHorizontalScrollIndicator = false
        HEImageViewPageCell.he.register(coll)
        coll.allowsSelection = false
        coll.isPagingEnabled = true
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
        bt.addTarget(self, action: #selector(clickOnResetToast), for: .touchUpInside)
        resetToastView = bt
    }
    
}



extension HEImageViewPagerController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
}

extension HEImageViewPagerController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        trace(currentIndex)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        trace(currentIndex)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let ord = (indexPath.row + 1)
        let total = imageStore.numberOfImages()
        indexLabel.text = "\(ord) / \(total)"
        
        trace()
        
        if let cell = cell as? HEImageViewPageCell, let hei = imageStore.getHEImage(at: indexPath.row) {
            cell.loadImage(task: imageCache.editImage(forHei: hei))
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visible = collectionView.visibleCells.first else { return }
        guard let index = collectionView.indexPath(for: visible)?.row else { return }
        
        let ord = (index + 1)
        let total = imageStore.numberOfImages()
        indexLabel.text = "\(ord) / \(total)"
        currentImage = imageStore.getHEImage(at: indexPath.row)
        currentIndex = indexPath.row
        trace()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageStore.numberOfImages()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEImageViewPageCell.he.identifier, for: indexPath) as! HEImageViewPageCell
        return cell
    }
    
}



class HEImageViewPageCell: UICollectionViewCell {
    
    private var imageView: UIImageView!
    private var imageLoadTask: Cancellable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                it.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                it.topAnchor.constraint(equalTo: contentView.topAnchor),
                it.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadImage(task: Task<UIImage, Error>) {
        
        trace()
        imageView.image = nil
        imageLoadTask?.cancel()
        imageLoadTask = Task { [weak self] in
            do {
                let image = try await task.value
                if Task.isCancelled { return }
                self?.imageView.image = image
            } catch {
                woops(error)
            }
        }
    }
}
