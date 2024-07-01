//
//  HEImageEditor.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import Combine

public protocol HEImageEditor: UIViewController {
    /// 연속 편집 모드 여부
    ///
    /// - true: 편집을 종료해도 이전 편집 상태를 유지한다.
    /// - false: (기본값) 편집을 종료하면, 편집 상태를 없애고 합쳐진 이미지로 변경한다.
    var continuouslyMode: Bool { get set }
    var editingImage: HEImage? { get }
    var currentIndex: Int? { get }

}

public protocol HEImageEditorDelegate: AnyObject {
    func didFinishEditImages(_ editor: HEImageEditor)
    func confirmingResetEditImage(_ editor: HEImageEditor, hei: HEImage, completion: @escaping (Bool) -> Void)
}

public extension HEImageEditorDelegate {
    func confirmingResetEditImage(_ editor: HEImageEditor, hei: HEImage, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}

/// 다수 이미지 편집기
///
/// - 내부적으로 HEEditImageView 를 편집모드로 사용한다.
open class HEImageEditorViewController: UIViewController, HEImageEditor {
    
    public weak var delegate: HEImageEditorDelegate?
    public weak var stickerDataSource: HEImageStickerTrayViewDataSource?
    
    public weak var imageStore: HEImageDataStore!
    public weak var imageCache: HEImageCache!
    
    public var continuouslyMode: Bool = false
    
    public private(set) var editingImage: HEImage?
    public private(set) var currentIndex: Int?
    
    private lazy var indexLabel: UILabel = {
       let lb = UILabel()
        lb.text = "0/0"
        lb.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lb.textColor = .he.rgba(246, 246, 246)
        return lb
    }()
    
    private var resetToastView: UIButton!
    private var collView: UICollectionView!
    private var bottomToolView: HEEditToolView!
    private var bottomToolViewHeight: CGFloat = 0
    private var topBarView: HETopBarView!
    private var topBarViewHeight: CGFloat = 0
    private var shouldLayout = true
    private var cancellables = Set<AnyCancellable>()
    private lazy var loadingView = HELoadingView()
    
    public init(imageStore: HEImageDataStore,
                imageCache: HEImageCache,
                stickerDataSource: HEImageStickerTrayViewDataSource?) {
        self.imageStore = imageStore
        self.imageCache = imageCache
        self.stickerDataSource = stickerDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
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
    
    private func showResetToastIfNeed(isEdited: Bool) {
        guard resetToastView.superview == nil else { return }
        view.addSubview(resetToastView)
        resetToastView.also { it in
            it.alpha = 0
            it.sizeToFit()
            it.layer.cornerRadius = it.bounds.height / 2
            it.isEnabled = isEdited
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
        delegate?.didFinishEditImages(self)
    }
    
    @objc
    private func clickOnResetToast() {
        guard let currentIndex, let hei = imageStore.getHEImage(at: currentIndex) else { return }
        if let delegate = delegate {
            delegate.confirmingResetEditImage(self, hei: hei) { [weak self] confirmed in
                if confirmed {
                    self?.executeReset(hei, index: currentIndex)
                }
            }
        }
    }
    
    private func executeReset(_ hei: HEImage, index: Int) {
        self.perform(#selector(self.hideResetToast), with: nil, afterDelay: 0.0)
        Task {
            hei.setEditState(nil)
            await imageCache.clearCached(forHei: hei, includeOrigin: false)
            collView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    private func makeTopBarView() -> (HETopBarView, CGFloat) {
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
    
    private func makeBottomToolView() -> (HEEditToolView, CGFloat) {
        // 기본 툴바
        var ts = HEConfiguration.default().tools
        if ts.contains(.imageSticker), HEConfiguration.default().imageStickerTray == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        let toolbar = HEEditImageBottomToolView(tools: ts)
        toolbar.toolSelectListener = { [weak self] type in
            self?.onBottomToolSelected(type: type)
        }
        return (toolbar, 76)
    }
    
    private func onBottomToolSelected(type: HEConfiguration.EditTool) {
        guard let currentIndex, let currentImage = imageStore.getHEImage(at: currentIndex) else {
            return
        }
        self.editingImage = currentImage
        Task { @MainActor in
           await self.startEditImage(hei: currentImage, tool: type)
        }
        .store(in: &cancellables)
        
    }
    
    private func setupHEConfiguration() {
        let stickerTray = HEImageStickerTrayView()
        stickerTray.dataSource = self.stickerDataSource
        HEConfiguration.default()
            .clipRatios([.origin, .custom, .wh1x1])
            .imageStickerTray(stickerTray)
    }
    
    
    // 편집 모드의 상단바 구성
    private func makeEditTopBarView() -> HEEditImageTopToolViewBuilder {
        return { editView in
            let topbar = HETopBarView()
            let cancelButton = UIButton()
            cancelButton.also { it in
                let icon = UIImage.he.getImage("ic_arrow_right") ?? UIImage(systemName: "chevron.left")
                it.setImage(icon, for: .normal)
                it.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
                it.drawDebugOutline()
            }
            topbar.addLeadingView(cancelButton)
            
            let confirmButton = UIButton()
            confirmButton.also { it in
                let icon = UIImage.he.getImage("icCheck") ?? UIImage(systemName: "checkmark")
                it.setImage(icon, for: .normal)
                it.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
                it.drawDebugOutline()
            }
            topbar.addTrailingView(confirmButton)
            
            cancelButton.addAction(.init(handler: { [weak editView] _ in editView?.cancel() }), for: .touchUpInside)
            confirmButton.addAction(.init(handler: { [weak editView] _ in editView?.done() }), for: .touchUpInside)
            
            return (topbar, 44)
        }
    }
    
    private func startEditImage(hei: HEImage, tool: HEConfiguration.EditTool?) async {
        let topBuilder = self.makeEditTopBarView()
        do {
            let image: UIImage
            var editState: HEEditState? = hei.editState
            if continuouslyMode {
                image = try await self.imageCache.originImage(forHei: hei).value
            } else {
                image = try await self.imageCache.editImage(forHei: hei).value
                editState = HEEditState(
                    drawPaths: editState?.drawPaths ?? [],
                    mosaicPaths: editState?.mosaicPaths ?? [],
                    clipStatus: nil,
                    adjustStatus: editState?.adjustStatus ?? HEAdjustStatus(),
                    selectFilter: editState?.selectFilter,
                    stickers: editState?.stickers ?? [],
                    actions: []
                )
            }
            
            setupHEConfiguration()
            
            let vc = HEEditImageViewController(image: image, editState: editState, topToolViewBuilder: topBuilder)
            vc.delegate = self
            vc.editId = hei.id
            vc.initialEditTool = tool
            vc.animateDismiss = true
            
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: false)
        } catch {
            woops(error)
        }
    }
}

extension HEImageEditorViewController: HEEditImageViewDelegate {
    
    public func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditState?) {
        
        bottomToolView?.unselectTool()
        editingImage = nil
        // 편집 데이터 교체
        guard let editId, let hei = imageStore.getHEImage(forId: editId) else {
            return
        }
        loadingView.show(inCenterOf: self.view)
        Task {
            hei.setEditState(editModel)
            do {
                let fileUrl = try await imageCache.cacheEditImage(uiImage: resultImage, forHei: hei).value
                trace(fileUrl)
                let thumbUrl = try await imageCache.cacheThumbnailImage(uiImage: resultImage, forHei: hei).value
                trace(thumbUrl)
            } catch {
                woops(error)
            }
            
            loadingView.hide()
            if let currentIndex, currentIndex < imageStore.numberOfImages() {
                collView.reloadItems(at: [IndexPath(row: currentIndex, section: 0)])
            }
        }
    }
    
    public func cancelledEditImage(_ editView: HEEditImageView) {
        bottomToolView?.unselectTool()
        editingImage = nil
    }
}


extension HEImageEditorViewController {
    
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
        bottomToolView.backgroundColor = .black
        view.addSubview(bottomToolView)
        
        let topBuilder = makeTopBarView()
        topBarView = topBuilder.0
        topBarViewHeight = topBuilder.1
        topBarView.backgroundColor = .black
        view.addSubview(topBarView)
        topBarView.hide(animate: false)
        
        let bt = UIButton()
        bt.layer.masksToBounds = true
        let icon = UIImage.he.getImage("ic_edit_refresh") ?? UIImage(systemName: "arrow.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .small))?.withTintColor(.white)
        bt.setImage(icon, for: .normal)
        bt.setImage(icon?.he.alpha(value: 0.4), for: .disabled)
        bt.setTitle("원본으로 초기화", for: .normal)
        bt.setTitleColor(UIColor.he.rgba(246, 246, 246), for: .normal)
        bt.setTitleColor(UIColor.he.rgba(246, 246, 246, 0.4), for: .disabled)
        bt.setBackgroundImage(UIImage().he.solid(UIColor.he.rgba(51, 51, 51, 0.4), width: 10, height: 10).resizableImage(withCapInsets: .zero, resizingMode: .tile), for: .normal)
        bt.setBackgroundImage(UIImage().he.solid(UIColor.he.rgba(51, 51, 51, 0.2), width: 10, height: 10).resizableImage(withCapInsets: .zero, resizingMode: .tile), for: .disabled)
        bt.titleLabel?.font = .systemFont(ofSize: 14)
        bt.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        bt.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16 + 2)
        bt.adjustsImageWhenHighlighted = false
        bt.addTarget(self, action: #selector(clickOnResetToast), for: .touchUpInside)
        resetToastView = bt
    }
    
}



extension HEImageEditorViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
}

extension HEImageEditorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
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
        currentIndex = indexPath.row
        trace()
        
        if let cell = cell as? HEImageViewPageCell, let hei = imageStore.getHEImage(at: indexPath.row) {
            cell.loadImage(task: imageCache.editImage(forHei: hei))
            
            if resetToastView.superview == nil {
                showResetToastIfNeed(isEdited: hei.editImageURL != nil)
            } else {
                hideResetToast()
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visible = collectionView.visibleCells.first else { return }
        guard let index = collectionView.indexPath(for: visible)?.row else { return }
        
        let ord = (index + 1)
        let total = imageStore.numberOfImages()
        indexLabel.text = "\(ord) / \(total)"
        currentIndex = index
        trace()
        
        if let hei = imageStore.getHEImage(at: index) {
            showResetToastIfNeed(isEdited: hei.editImageURL != nil)
        }
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
