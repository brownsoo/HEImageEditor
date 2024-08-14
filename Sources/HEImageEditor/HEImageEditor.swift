//
//  HEImageEditor.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/4/24.
//

import Foundation
import UIKit
import Combine
import HECommon

public protocol HEImageEditor: UIViewController {
    var imageStore: HECommon.HEEditImageStore { get set }
    var editingImage: HEEditImage? { get }
    var currentIndex: Int? { get }
}

public protocol HEImageEditorDelegate: AnyObject {
    func didFinishEditImages(_ editor: HEImageEditor)
    func didCancelEditImages(_ editor: HEImageEditor)
    func confirmingResetEditImage(_ editor: HEImageEditor, hei: HEEditImage, completion: @escaping (Bool) -> Void)
    
    func cannotAttachMoreImageStickers(_ editor: HEImageEditor)
    func cannotAttachMoreTextStickers(_ editor: HEImageEditor)
}

public extension HEImageEditorDelegate {
//    func didCancelEditImages(_ editor: HEImageEditor) {}
    func confirmingResetEditImage(_ editor: HEImageEditor, hei: HEEditImage, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    func cannotAttachMoreImageStickers(_ editor: HEImageEditor) {
        (self as? UIViewController)?.showAlert(text: EditorConfig.wordings.alert.cannotMoreImageStickers)
    }
    func cannotAttachMoreTextStickers(_ editor: HEImageEditor) {
        (self as? UIViewController)?.showAlert(text: EditorConfig.wordings.alert.cannotMoreTextStickers)
    }
}

enum TouchStickerType {
    case image
    case text
}

/// 다수 이미지 편집기
///
/// - 내부적으로 HEEditImageView 를 편집모드로 사용한다.
open class HEImageEditorViewController: UIViewController, HEImageEditor {
    
    public weak var delegate: HEImageEditorDelegate?
    public weak var stickerDataSource: HEImageStickerTrayViewDataSource? {
        didSet {
            HEImageEditorConfiguration.default().imageStickerTray?.dataSource = stickerDataSource
        }
    }
    /// 편집 정보를 제공
    public var imageStore: HECommon.HEEditImageStore
    
    public private(set) var editingImage: HEEditImage?
    public private(set) var currentIndex: Int?
    
    public var initialIndex: Int = 0
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
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
    
    deinit {
        HEImageEditorConfiguration.default().imageStickerTray(nil)
        trace()
    }
    
    public init(imageStore: HEEditImageStore,
                stickerDataSource: HEImageStickerTrayViewDataSource?) {
        self.imageStore = imageStore
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
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }
        shouldLayout = false
        
        let insets = self.view.safeAreaInsets
        
        topBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top + topBarViewHeight)
        
        bottomToolView.frame = CGRect(x: 0,
                                      y: view.frame.height - bottomToolViewHeight - insets.bottom,
                                      width: view.bounds.width,
                                      height: bottomToolViewHeight + insets.bottom)
        let top = topBarView.frame.maxY
        collView.frame = CGRect(x: 0,
                                y: top,
                                width: view.bounds.width,
                                height: bottomToolView.frame.minY - top)
        if initialIndex > 0 && initialIndex < imageStore.all().count {
            collView.isPagingEnabled = false
            collView.scrollToItem(at: IndexPath(row: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
            collView.isPagingEnabled = true
        }
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
        delegate?.didCancelEditImages(self)
        
        if let nc = self.navigationController, nc.viewControllers.count > 1 {
            nc.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @objc
    private func didConfirmClick() {
        delegate?.didFinishEditImages(self)
    }
    
    @objc
    private func clickOnResetToast() {
        guard let currentIndex, let hei = imageStore.getHEImage(at: currentIndex) as? HEEditImage else { return }
        if let delegate = delegate {
            delegate.confirmingResetEditImage(self, hei: hei) { [weak self] confirmed in
                if confirmed {
                    self?.executeReset(hei, index: currentIndex)
                }
            }
        }
    }
    
    private func executeReset(_ hei: HEEditImage, index: Int) {
        self.perform(#selector(self.hideResetToast), with: nil, afterDelay: 0.0)
        Task {
            hei.setEditState(nil)
            await imageStore.clearCached(forHei: hei, includeOrigin: false)
            collView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    /// 상단 툴바
    private func makeTopBarView() -> (HETopBarView, CGFloat) {
        let topbar = HETopBarView()
        let cancelButton = UIButton()
        cancelButton.also { it in
            let icon = UIImage.he.getImage("icArrowRight") ?? UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .default))
            it.setImage(icon, for: .normal)
            it.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
        topbar.addLeadingView(cancelButton)
        
        let confirmButton = UIButton()
        confirmButton.also { it in
            it.setTitle(EditorConfig.wordings.completePick, for: .normal)
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
        
        return (topbar, HETopBarView.contentHeight)
    }
    
    /// 메인 하단 툴바
    private func makeBottomToolView() -> (HEEditToolView, CGFloat) {
        setupHEConfiguration()
        var ts = HEImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), HEImageEditorConfiguration.default().imageStickerTray == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        let toolbar = HEEditImageBottomToolView(tools: ts)
        toolbar.toolSelectListener = { [weak self] type in
            self?.onBottomToolSelected(type: type)
        }
        return (toolbar, 76)
    }
    
    private func onBottomToolSelected(type: HEImageEditorConfiguration.EditTool) {
        startEditCurrent(type: type, stickerId: nil)
    }
    
    private func setupHEConfiguration() {
        if HEImageEditorConfiguration.default().tools.contains(.imageSticker) {
            let stickerTray = HEImageEditorConfiguration.default().imageStickerTray ?? HEImageStickerTrayView()
            stickerTray.dataSource = self.stickerDataSource
            HEImageEditorConfiguration.default()
                .imageStickerTray(stickerTray)
        } else {
            HEImageEditorConfiguration.default()
                .imageStickerTray(nil)
        }
    }
    
    // 편집 모드의 상단바 구성
    private func makeEditTopBarView() -> HEEditImageTopToolViewBuilder {
        return { editView in
            let topbar = HETopBarView()
            topbar.backgroundColor = .black
            let cancelButton = UIButton()
            cancelButton.also { it in
                let icon = UIImage.he.getImage("icArrowRight") ?? UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .default))
                it.setImage(icon, for: .normal)
                it.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            }
            topbar.addLeadingView(cancelButton)
            
            let confirmButton = UIButton()
            confirmButton.also { it in
                let icon = UIImage.he.getImage("icCheck") ?? UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .default))
                it.setImage(icon, for: .normal)
                it.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            }
            topbar.addTrailingView(confirmButton)
            
            cancelButton.addAction(.init(handler: { [weak editView] _ in editView?.cancel() }), for: .touchUpInside)
            confirmButton.addAction(.init(handler: { [weak editView] _ in editView?.done() }), for: .touchUpInside)
            
            return (topbar, HETopBarView.contentHeight)
        }
    }
    
    
    private func startEditCurrent(type: HEImageEditorConfiguration.EditTool, stickerId: String?) {
        guard let currentIndex, let he = imageStore.getHEImage(at: currentIndex) else {
            return
        }
        // 편집 데이터가 없는 경우, 모델 변환
        let hei: HEEditImage
        if (he as? HEEditImage) == nil {
            hei = he.toEditImage()!
            imageStore.replaceHEImage(at: currentIndex, with: he.toEditImage()!)
        } else {
            hei = he.toEditImage()!
        }
        
        self.editingImage = hei
        Task { @MainActor in
           await self.showImageEditor(hei: hei, tool: type, stickerId: stickerId)
        }
        .store(in: &cancellables)
    }
    
    
    private func showImageEditor(hei: HEEditImage,
                                 tool: HEImageEditorConfiguration.EditTool?,
                                 stickerId: String?) async {
        let topBuilder = self.makeEditTopBarView()
        do {
            var image: UIImage
            let editState: HEEditState? = hei.editState
            
            if hei.editImageURL != nil && (editState?.fattened == true || hei.fattenImageURL != nil) {
                image = try await self.imageStore.fattenImage(forHei: hei).value
            } else {
                if hei.editImageURL == nil && hei.originURL?.pathExtension == "gif" {
                    image = try await self.imageStore.originImage(forHei: hei).value
                    //trace(image.he.isGIF())
                    if let first = image.jpegData(compressionQuality: 0.8), let stop = UIImage(data: first) {
                        image = stop
                        let _ = self.imageStore.cacheFattenImage(uiImage: stop, forHei: hei)
                    }
                } else {
                    image = try await self.imageStore.editImage(forHei: hei).value
                }
            }
            
            setupHEConfiguration()
            
            let vc = HEEditImageViewController(image: image, editState: editState, topToolViewBuilder: topBuilder)
            vc.delegate = self
            vc.editId = hei.id
            vc.initialEditTool = tool
            vc.initialStickerId = stickerId
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
        guard let editId, let hei = imageStore.getHEImage(forId: editId) as? HEEditImage else {
            woops("!!!")
            return
        }
        loadingView.show(inCenterOf: self.view)
        Task {
            hei.setEditState(editModel)
            do {
                let _ = try await imageStore.cacheEditImage(uiImage: resultImage, forHei: hei).value
                let _ = try await imageStore.cacheThumbnailImage(uiImage: resultImage, forHei: hei).value
                if hei.fattenImageURL == nil { // 편집으로 진입시, 중간 편집본으로 진행하도록 하기 위해 원본으로 지정 
                    let originImage = try await imageStore.originImage(forHei: hei).value
                    let _ = try await imageStore.cacheFattenImage(uiImage: originImage, forHei: hei).value
                }
            } catch {
                woops(error)
            }
            
            debugPrint(hei)
            
            loadingView.hide()
            if let currentIndex, currentIndex < imageStore.numberOfImages() {
                collView.reloadItems(at: [IndexPath(row: currentIndex, section: 0)])
            }
        }
    }
    
    public func didClipWithoutKeepingState(_ editView: any HEEditImageView, resultImage: UIImage, editId: String?) {
        guard let editId, let hei = imageStore.getHEImage(forId: editId) as? HEEditImage else {
            return
        }
        loadingView.show(inCenterOf: self.view)
        Task {
            do {
                let _ = try await imageStore.cacheFattenImage(uiImage: resultImage, forHei: hei).value
            } catch {
                woops(error)
            }
            debugPrint(hei)
            loadingView.hide()
        }
    }
    
    public func cancelledEditImage(_ editView: HEEditImageView) {
        bottomToolView?.unselectTool()
        editingImage = nil
    }
    
    public func cannotAttachMoreImageStickers(_ editView: HEEditImageView) {
        delegate?.cannotAttachMoreImageStickers(self)
    }
    
    public func cannotAttachMoreTextStickers(_ editView: HEEditImageView) {
        delegate?.cannotAttachMoreTextStickers(self)
    }
    
    
}


extension HEImageEditorViewController {
    
    private func setupUI() {
        
        view.backgroundColor = .black
        
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
        let icon = UIImage.he.getImage("icEditRefresh") ?? UIImage(systemName: "arrow.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .small))?.withTintColor(.white)
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
//        trace()
        
        if let cell = cell as? HEImageViewPageCell, let hei = imageStore.getHEImage(at: indexPath.row) {
            cell.loadImage(task: imageStore.editImage(forHei: hei), editState: (hei as? HEEditImage)?.editState)
            
            if resetToastView.superview == nil {
                showResetToastIfNeed(isEdited: hei.editImageURL != nil)
            } else {
                hideResetToast()
            }
            
            cell.delegate = self
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visible = collectionView.visibleCells.first else { return }
        guard let index = collectionView.indexPath(for: visible)?.row else { return }
        
        let ord = (index + 1)
        let total = imageStore.numberOfImages()
        indexLabel.text = "\(ord) / \(total)"
        currentIndex = index
//        trace()
        
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

extension HEImageEditorViewController: HEImageViewPageCellDelegate {
    func imageViewPageCell(_ cell: HEImageViewPageCell, tapOnStickerId stickerId: String, stickerType: TouchStickerType) {
        if stickerType == .image {
            startEditCurrent(type: .imageSticker, stickerId: stickerId)
        } else {
            startEditCurrent(type: .textSticker, stickerId: stickerId)
        }
    }
}


protocol HEImageViewPageCellDelegate: AnyObject {
    func imageViewPageCell(_ cell: HEImageViewPageCell, tapOnStickerId stickerId: String, stickerType: TouchStickerType)
}

struct StickerArea {
    let id: String
    let center: CGPoint
    let radius: CGFloat
    let width: CGFloat
    let height: CGFloat
    let type: TouchStickerType
    let rotation: CGFloat
}

class HEImageViewPageCell: UICollectionViewCell {
    
    private var imageView: UIImageView!
    private var imageLoadTask: Cancellable?
    private var stickerAreas: [StickerArea] = []
    private lazy var tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    weak var delegate: HEImageViewPageCellDelegate?
    
    private let previewArea = UIView()
    
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
        
        contentView.addSubview(previewArea)
        contentView.addGestureRecognizer(tapGes)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadImage(task: Task<UIImage, Error>, editState: HEEditState?) {
//        trace()
        imageView.image = nil
        imageLoadTask?.cancel()
        imageLoadTask = Task { [weak self] in
            do {
                let image = try await task.value
                if Task.isCancelled { return }
                self?.imageView.image = image
                self?.getStickerAreas(editState)
            } catch {
                woops(error)
            }
        }
    }
    
    private func getStickerAreas(_ editState: HEEditState?) {
        guard let editState else { return }
        let screenScale = UIScreen.main.scale
        let imageRect = imageView.calculateScaleFitRectOfImage()
        var areas: [StickerArea] = []
        for sticker in editState.stickers {
            var visibleFrame = sticker.visibleFrame
            visibleFrame.origin.x += imageRect.origin.x
            visibleFrame.origin.y += imageRect.origin.y
            
            let length = (sticker.originFrame.width + sticker.originFrame.height) / 2
            var radius = (length - HEImageStickerView.edgeInset * screenScale) * sticker.originScale * sticker.gesScale
            radius = max(0, radius)
            areas.append(StickerArea(
                id: sticker.id,
                center: CGPoint(x: visibleFrame.midX, y: visibleFrame.midY),
                radius: radius,
                width: visibleFrame.width,
                height: visibleFrame.height,
                type: sticker.isTextSticker ? TouchStickerType.text : .image,
                rotation: sticker.originAngle + sticker.gesRotation
            ))
        }
        
        self.stickerAreas = areas.reversed()
        
        // 이하 : 테스트 영역 체크용
//        if let area = areas.first {
//            
//            debugPrint(area)
//            
//            previewArea.backgroundColor = .yellow.withAlphaComponent(0.3)
//            previewArea.layer.masksToBounds = true
////            let length = min(area.width, area.height)
////            previewArea.frame = CGRect(x: area.center.x - length / 2,
////                                       y: area.center.y - length / 2,
////                                       width: length,
////                                       height: length)
//            previewArea.frame = CGRect(x: area.center.x - area.radius / 2,
//                                       y: area.center.y - area.radius / 2,
//                                       width: area.radius,
//                                       height: area.radius)
//            previewArea.layer.cornerRadius = area.radius / 2
//        }
    }
    
    @objc
    private func tapAction(_ ges: UITapGestureRecognizer) {
        let p = ges.location(in: contentView)
        guard let area = stickerAreas.first (where: { area in
            let dis = sqrt(pow(p.x - area.center.x, 2) + pow(p.y - area.center.y, 2))
            return dis < area.radius / 2
        }) else {
            return
        }
        
        trace(area)
        delegate?.imageViewPageCell(self, tapOnStickerId: area.id, stickerType: area.type)
        
    }
}


fileprivate extension UIImageView {
    func calculateScaleFitRectOfImage() -> CGRect {
        guard var imgSize = self.image?.size else {
            return .zero
        }
        let vSize = self.frame.size
        let scaleW = vSize.width / imgSize.width
        let scaleH = vSize.height / imgSize.height
        let aspect = min(scaleW, scaleH)
        imgSize = CGSize(width: imgSize.width * aspect, height: imgSize.height * aspect)
        var imageRect = CGRect(origin: .zero, size: imgSize)
        imageRect.origin.x = (vSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (vSize.height - imageRect.size.height) / 2
        
        imageRect.origin.x += self.frame.origin.x
        imageRect.origin.y += self.frame.origin.y
        
        return imageRect
    }
}
