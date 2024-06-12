//
//  HEClipImageViewController.swift
//  HEImageEditor
//

import UIKit

public typealias HEClipImageBottomViewBuilder = (HEClipImageView) -> (toolView: UIView, height: CGFloat)

public protocol HEClipImageView: AnyObject {
    func revertEdit()
    /// 편집 완료
    func doneEdit()
    /// 편집 취소
    func cancelEdit()
    func rotate()
    func clip(ratio: HEImageClipRatio)
}

extension HEClipImageViewController {
    enum ClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

class HEClipImageViewController: UIViewController, HEClipImageView {
    
    
    private var animateDismiss = true
    
    /// Animation starting frame when first enter
    var presentAnimateFrame: CGRect?
    
    /// Animation image
    var presentAnimateImage: UIImage?
    
    /// Animation starting frame when cancel clip
    private var cancelClipAnimateFrame: CGRect = .zero
    
    private var viewDidAppearCount = 0
    
    private let originalImage: UIImage
    
    private var editImage: UIImage
    /// 편집 영역
    private(set) var editRect: CGRect
    /// 편집 영역을 화면 안쪽으로 넣을 수 있음.
    private var editRectInsets: UIEdgeInsets = .init(top: 48,  // 상위뷰의 툴바 영역
                                             left: 0,
                                             bottom: 72, // 하위 탭바 영역
                                             right: 0)
    
    private var scrollView: UIScrollView!
    private var containerView: UIView!
    private var imageView: UIImageView!
    
    /// 잘려진 부분을 희미하게 보이기 위한 레이어
    private var dimView: HEClipShadowView!
    private var gridView: HEClipGridView!
    private var gridPanGes: UIPanGestureRecognizer!
    
    /// 툴바 아래에 놓을 수 있는 뷰.
    ///
    /// - HEClipImageBottomViewBuilder 에 의해 생성
    private var bottomView: UIView?
    private var bottomViewHeight: CGFloat = 0
    
    var bottomShadowLayer: CAGradientLayer!
    private var topView: UIView!
    private var cancelButton: UIButton!
    private var confirmButton: UIButton!
    /// 회전, 크롭 툴 아이템 뷰
    private var clipActionToolView: HEClipActionToolView!
    
    private var shouldLayout = true
    
    var panEdge: HEClipImageViewController.ClipPanEdge = .none
    
    var beginPanPoint: CGPoint = .zero
    
    var clipBoxFrame: CGRect = .zero
    
    var clipOriginFrame: CGRect = .zero
    
    var isRotating = false
    
    private(set) var angle: CGFloat = 0
    
    var selectedRatio: HEImageClipRatio {
        didSet {
            gridView.isCircle = selectedRatio.isCircle
        }
    }
    
    var thumbnailImage: UIImage?
    
    lazy var maxClipFrame = calculateMaxClipFrame()
    
    var minClipSize = CGSize(width: 45, height: 45)
    
    var resetTimer: Timer?
    
    var dismissAnimateFromRect: CGRect = .zero
    
    var dismissAnimateImage: UIImage?
    
    // Angle, edit rect,
    var clipDoneBlock: ((_ angle: CGFloat, _ editRect: CGRect, _ selectRatio: HEImageClipRatio) -> Void)?
    
    var cancelClipBlock: (() -> Void)?
    
    var dismissCallback: (() -> Void)?
    
    override var prefersStatusBarHidden: Bool { true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true}
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    private var bottomViewBuilder: HEClipImageBottomViewBuilder?
    
    deinit {
        trace()
        self.cleanTimer()
    }
    
    init(image: UIImage, status: HEClipStatus, bottomViewBuilder: HEClipImageBottomViewBuilder?) {
        self.originalImage = image
        self.editRect = status.editRect
        self.angle = status.angle
        if angle == -90 {
            editImage = image.he.rotate(orientation: .left)
        } else if self.angle == -180 {
            editImage = image.he.rotate(orientation: .down)
        } else if self.angle == -270 {
            editImage = image.he.rotate(orientation: .right)
        } else {
            editImage = image
        }
        var firstEnter = false
        if let ratio = status.ratio {
            selectedRatio = ratio
        } else {
            firstEnter = true
            selectedRatio = HEImageEditorConfiguration.default().clipRatios.first!
        }
        
        self.clipActionToolView = HEClipActionToolView(clipRatios: HEImageEditorConfiguration.default().clipRatios,
                                                       originImageSize: image.size,
                                                       selectedRatio: self.selectedRatio)
        self.bottomViewBuilder = bottomViewBuilder
        
        super.init(nibName: nil, bundle: nil)
        
        self.clipActionToolView.delegate = self
        if firstEnter {
            calculateEditRect()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        Task.detached {
            await self.generateThumbnailImage()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearCount += 1
        if presentingViewController is HEEditImageViewController {
            transitioningDelegate = self
        }
        
        guard viewDidAppearCount == 1 else {
            return
        }
        
        if let frame = presentAnimateFrame, let image = presentAnimateImage {
            let animateImageView = UIImageView(image: image)
            animateImageView.contentMode = .scaleAspectFill
            animateImageView.clipsToBounds = true
            animateImageView.frame = frame
            view.addSubview(animateImageView)
            
            cancelClipAnimateFrame = clipBoxFrame
            UIView.animate(withDuration: 0.25, animations: {
                animateImageView.frame = self.clipBoxFrame
                self.bottomView?.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.scrollView.alpha = 1
                    self.gridView.alpha = 1
                }) { _ in
                    animateImageView.removeFromSuperview()
                }
            }
        } else {
            bottomView?.alpha = 1
            scrollView.alpha = 1
            gridView.alpha = 1
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shouldLayout else { return }
        shouldLayout = false
        
        let bottomToolFrame: CGRect
        if let bottomView {
            bottomView.frame = CGRect(x: 0, y: view.bounds.height - self.bottomViewHeight, width: view.bounds.width, height: self.bottomViewHeight)
            bottomToolFrame = bottomView.frame
        } else {
            bottomToolFrame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 0)
        }
        let toolViewTop = bottomToolFrame.minY - HEClipActionToolView.viewHeight
        
        topView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: view.bounds.width, height: 48)
        confirmButton.frame.origin.x = view.bounds.width - 44
        
        clipActionToolView.frame = CGRect(x: 0, y: toolViewTop, width: view.bounds.width, height: HEClipActionToolView.viewHeight)
        clipActionToolView.selectRatio(self.selectedRatio, animated: false)
        
        scrollView.frame = view.bounds
        dimView.frame = view.bounds
        
        layoutInitialImage()
        
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
        maxClipFrame = calculateMaxClipFrame()
    }
    
    private func setupUI() {
        scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        containerView = UIView()
        scrollView.addSubview(containerView)
        
        imageView = UIImageView(image: editImage)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        
        dimView = HEClipShadowView()
        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(dimView)
        
        gridView = HEClipGridView()
        gridView.isUserInteractionEnabled = false
        gridView.isCircle = selectedRatio.isCircle
        view.addSubview(gridView)
        
        if let builder  = self.bottomViewBuilder?(self) {
            view.addSubview(builder.toolView)
            self.bottomView = builder.toolView
            self.bottomViewHeight = builder.height
        }
        
        // 상단 툴바
        cancelButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        cancelButton.setImage(.he.getImage("icClose24")?.withRenderingMode(.alwaysOriginal), for: .normal)
        confirmButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        confirmButton.setImage(.he.getImage("icCheck")?.withRenderingMode(.alwaysOriginal), for: .normal)
        topView = UIView()
        topView.addSubview(cancelButton)
        topView.addSubview(confirmButton)
        view.addSubview(topView)
        topView.backgroundColor = .yellow.withAlphaComponent(0.2)
        
        cancelButton.addAction(.init(handler: { [weak self] _ in self?.cancelEdit() }), for: .touchUpInside)
        confirmButton.addAction(.init(handler: { [weak self] _ in self?.doneEdit() }), for: .touchUpInside)
        
        // 툴바
        view.addSubview(clipActionToolView)
        
        gridPanGes = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        gridPanGes.delegate = self
        view.addGestureRecognizer(gridPanGes)
        scrollView.panGestureRecognizer.require(toFail: gridPanGes)
        
        scrollView.alpha = 0
        gridView.alpha = 0
        bottomView?.alpha = 0
    }
    
    func generateThumbnailImage() {
        let size: CGSize
        let ratio = (editImage.size.width / editImage.size.height)
        let fixLength: CGFloat = 100
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        thumbnailImage = editImage.he.resize(size)
    }
    
    /// Calculate the maximum cropping range
    private func calculateMaxClipFrame() -> CGRect {
        var editInsets = self.editRectInsets
        let insets = deviceSafeAreaInsets()
        editInsets.top += insets.top
        var rect = CGRect.zero
        rect.origin.x = editInsets.left
        rect.origin.y = insets.top
        rect.size.width = UIScreen.main.bounds.width - editInsets.width
        rect.size.height = UIScreen.main.bounds.height - editInsets.top - self.bottomViewHeight - HEClipActionToolView.viewHeight - insets.bottom
        return rect
    }
    
    private func calculateEditRect() {
        if selectedRatio.whRatio == 0 {
            editRect = CGRect(origin: .zero, size: editImage.size)
        } else {
            let imageSize = editImage.size
            let imageWHRatio = imageSize.width / imageSize.height
            
            var w: CGFloat = 0, h: CGFloat = 0
            if selectedRatio.whRatio >= imageWHRatio {
                w = imageSize.width
                h = w / selectedRatio.whRatio
            } else {
                h = imageSize.height
                w = h * selectedRatio.whRatio
            }
            
            editRect = CGRect(x: (imageSize.width - w) / 2, y: (imageSize.height - h) / 2, width: w, height: h)
        }
    }
    
    private func layoutInitialImage() {
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = 1
        
        let editSize = editRect.size
        scrollView.contentSize = editSize
        let maxClipRect = maxClipFrame
        
        containerView.frame = CGRect(origin: .zero, size: editImage.size)
        imageView.frame = containerView.bounds
        
        // editRect 비율, editRect가 차지하는 프레임을 계산.
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        // 현재 잘린 직사각형 영역을 계산.
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width - frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height - frame.height) / 2)
        
        // 편집 이미지에 따라 최소 줌 비율을 계산
        let originalScale = max(frame.width / editImage.size.width, frame.height / editImage.size.height)
        
        // 원본을 기준으로 편집 사각형의 크기를 조정합니다.
        // 사진이 확대되지 않은 경우 클립 사각형으로 크기를 조정합니다.
        let scaleEditSize = CGSize(width: editRect.width * originalScale, height: editRect.height * originalScale)
        // maxClipRect에 대한 크기 조정된 클립 직사각형의 비율을 계산합니다.
        let clipRectZoomScale = min(maxClipRect.width / scaleEditSize.width, maxClipRect.height / scaleEditSize.height)
        
        scrollView.minimumZoomScale = originalScale
        scrollView.maximumZoomScale = 10
        // 현재 확대/축소 배율 설정
        let zoomScale = clipRectZoomScale * originalScale
        scrollView.zoomScale = zoomScale
        scrollView.contentSize = CGSize(width: editImage.size.width * zoomScale, height: editImage.size.height * zoomScale)
        
        changeClipBoxFrame(newFrame: frame)
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((scrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((scrollView.frame.height - scaledSize.height) / 2)
            scrollView.contentOffset = offset
        }
        
        // 이미지 크기에 따른 편집 직사각형의 오프셋
        let diffX = editRect.origin.x / editImage.size.width * scrollView.contentSize.width
        let diffY = editRect.origin.y / editImage.size.height * scrollView.contentSize.height
        scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left + diffX, y: -scrollView.contentInset.top + diffY)
    }
    
    private func changeClipBoxFrame(newFrame: CGRect) {
        guard clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        let originX = ceil(maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = max(frame.minX, originX)
//        frame.origin.x = floor(max(frame.minX, originX))
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = max(frame.minY, originY)
//        frame.origin.y = floor(max(frame.minY, originY))
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = maxClipFrame.width + maxClipFrame.minX - frame.minX
        frame.size.width = max(minClipSize.width, min(frame.width, maxW))
//        frame.size.width = floor(max(self.minClipSize.width, min(frame.width, maxW)))
        
        let maxH = maxClipFrame.height + maxClipFrame.minY - frame.minY
        frame.size.height = max(minClipSize.height, min(frame.height, maxH))
//        frame.size.height = floor(max(self.minClipSize.height, min(frame.height, maxH)))
        
        clipBoxFrame = frame
        dimView.clearRect = frame
        gridView.frame = frame// .insetBy(dx: -HEClipOverlayView.cornerLineWidth, dy: -HEClipOverlayView.cornerLineWidth)
        
        scrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: scrollView.frame.maxY - frame.maxY, right: scrollView.frame.maxX - frame.maxX)
        
        let scale = max(frame.height / editImage.size.height, frame.width / editImage.size.width)
        scrollView.minimumZoomScale = scale
        
//        var size = self.scrollView.contentSize
//        size.width = floor(size.width)
//        size.height = floor(size.height)
//        self.scrollView.contentSize = size
        
        scrollView.zoomScale = scrollView.zoomScale
    }
    
    private func mimicAnimateDismiss(completion: @escaping (() -> Void)) {
        guard let presentAnimateFrame else {
            completion()
            return
        }
        let imageView = UIImageView(frame: dismissAnimateFromRect)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = dismissAnimateImage
        view.addSubview(imageView)
        self.imageView.isHidden = true
        self.gridView.isHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            imageView.frame = presentAnimateFrame
        }) { _ in
            imageView.removeFromSuperview()
            self.imageView.isHidden = false
            self.gridView.isHidden = false
            completion()
        }
    }
    
    func cancelEdit() {
        dismissAnimateFromRect = cancelClipAnimateFrame
        dismissAnimateImage = presentAnimateImage
        cancelClipBlock?()
        if self.presentingViewController is HEEditImageViewController {
            dismiss(animated: animateDismiss, completion: dismissCallback)
        } else {
            mimicAnimateDismiss { [weak self] in
                self?.dismissCallback?()
            }
        }
    }
    
    
    func doneEdit() {
        let image = clipImage()
        dismissAnimateFromRect = clipBoxFrame
        dismissAnimateImage = image.clipImage
        clipDoneBlock?(angle, image.editRect, selectedRatio)
        if self.presentingViewController is HEEditImageViewController {
            dismiss(animated: animateDismiss, completion: dismissCallback)
        } else {
            mimicAnimateDismiss { [weak self] in
                self?.dismissCallback?()
            }
        }
    }
    
    /// 초기화
    func revertEdit() {
        angle = 0
        editImage = originalImage
        calculateEditRect()
        imageView.image = editImage
        layoutInitialImage()
        
        generateThumbnailImage()
        
    }
    
    func rotate() {
        guard !isRotating else {
            return
        }
        angle -= 90
        if angle == -360 {
            angle = 0
        }
        
        isRotating = true
        
        let animateImageView = UIImageView(image: editImage)
        animateImageView.contentMode = .scaleAspectFit
        animateImageView.clipsToBounds = true
        let originFrame = view.convert(containerView.frame, from: scrollView)
        animateImageView.frame = originFrame
        view.addSubview(animateImageView)
        
        if selectedRatio.whRatio == 0 || selectedRatio.whRatio == 1 {
            // 자유 비율 및 1:1 비율, 직사각형 변환 편집
            
            //편집 사각형을 편집 이미지에 상대적인 사각형으로 변환합니다.
            let rect = convertClipRectToEditImageRect()
            editImage = editImage.he.rotate(orientation: .left)
            // 직사각형을 회전하고 회전된 편집 이미지를 기준으로 직사각형으로 변환합니다.
            editRect = CGRect(x: rect.minY, y: editImage.size.height - rect.minX - rect.width, width: rect.height, height: rect.width)
        } else {
            // 다른 비율의 자르기 프레임은 회전 후 바로 편집할 수 있도록 재설정됩니다.
            
            // 이미지 회전
            editImage = editImage.he.rotate(orientation: .left)
            calculateEditRect()
        }
        
        imageView.image = editImage
        layoutInitialImage()
        
        let toFrame = view.convert(containerView.frame, from: scrollView)
        let transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        gridView.alpha = 0
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            animateImageView.transform = transform
            animateImageView.frame = toFrame
        }) { _ in
            animateImageView.removeFromSuperview()
            self.gridView.alpha = 1
            self.containerView.alpha = 1
            self.isRotating = false
        }
        
        generateThumbnailImage()
    }
    
    func clip(ratio: HEImageClipRatio) {
        self.selectedRatio = ratio
        self.calculateEditRect()
        self.layoutInitialImage()
    }
    
    /// 그리드 패닝
    @objc func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: view)
        if pan.state == .began {
            startEditing()
            beginPanPoint = point
            clipOriginFrame = clipBoxFrame
            panEdge = calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard panEdge != .none else {
                return
            }
            updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            panEdge = .none
            startTimer()
        }
    }
    
    func calculatePanEdge(at point: CGPoint) -> HEClipImageViewController.ClipPanEdge {
        let frame = clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let cornerSize = CGSize(width: 60, height: 60)
        let topLeftRect = CGRect(origin: frame.origin, size: cornerSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: cornerSize)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height))
        if topRect.contains(point) {
            return .top
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height))
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    func updateClipBoxFrame(point: CGPoint) {
        var frame = clipBoxFrame
        let originFrame = clipOriginFrame
        
        var newPoint = point
        newPoint.x = max(maxClipFrame.minX, newPoint.x)
        newPoint.y = max(maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - beginPanPoint.x)
        let diffY = ceil(newPoint.y - beginPanPoint.y)
        let ratio = selectedRatio.whRatio
        
        switch panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            if ratio != 0 {
                frame.size.height = originFrame.height - diffX / ratio
            }
            
        case .right:
            frame.size.width = originFrame.width + diffX
            if ratio != 0 {
                frame.size.height = originFrame.height + diffX / ratio
            }
            
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            if ratio != 0 {
                frame.size.width = originFrame.width - diffY * ratio
            }
            
        case .bottom:
            frame.size.height = originFrame.height + diffY
            if ratio != 0 {
                frame.size.width = originFrame.width + diffY * ratio
            }
            
        case .topLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffX / ratio
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
            
        case .topRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY - diffX / ratio
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
            
        case .bottomLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height + diffY
            }
            
        case .bottomRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffY
            }
            
        default:
            break
        }
        
        let minSize: CGSize
        let maxSize: CGSize
        let maxClipFrame: CGRect
        if ratio != 0 {
            if ratio >= 1 {
                minSize = CGSize(width: minClipSize.height * ratio, height: minClipSize.height)
            } else {
                minSize = CGSize(width: minClipSize.width, height: minClipSize.width / ratio)
            }
            if ratio > self.maxClipFrame.width / self.maxClipFrame.height {
                maxSize = CGSize(width: self.maxClipFrame.width, height: self.maxClipFrame.width / ratio)
            } else {
                maxSize = CGSize(width: self.maxClipFrame.height * ratio, height: self.maxClipFrame.height)
            }
            maxClipFrame = CGRect(origin: CGPoint(x: self.maxClipFrame.minX + (self.maxClipFrame.width - maxSize.width) / 2, y: self.maxClipFrame.minY + (self.maxClipFrame.height - maxSize.height) / 2), size: maxSize)
        } else {
            minSize = minClipSize
            maxSize = self.maxClipFrame.size
            maxClipFrame = self.maxClipFrame
        }
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(maxClipFrame.maxX - minSize.width, max(frame.origin.x, maxClipFrame.minX))
        frame.origin.y = min(maxClipFrame.maxY - minSize.height, max(frame.origin.y, maxClipFrame.minY))
        
        if panEdge == .topLeft || panEdge == .bottomLeft || panEdge == .left, frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if panEdge == .topLeft || panEdge == .topRight || panEdge == .top, frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        changeClipBoxFrame(newFrame: frame)
    }
    
    func startEditing() {
        cleanTimer()
        dimView.alpha = 0
        gridView.isEditing = true
        if clipActionToolView.alpha != 0 {
            clipActionToolView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2) {
                self.clipActionToolView.alpha = 0
            }
        }
    }
    
    @objc func endEditing() {
        gridView.isEditing = false
        moveClipContentToCenter()
    }
    
    func startTimer() {
        cleanTimer()
        resetTimer = Timer.scheduledTimer(timeInterval: 0.8, target: HEWeakProxy(target: self), selector: #selector(endEditing), userInfo: nil, repeats: false)
        RunLoop.current.add(resetTimer!, forMode: .common)
    }
    
    func cleanTimer() {
        resetTimer?.invalidate()
        resetTimer = nil
    }
    
    func moveClipContentToCenter() {
        let maxClipRect = maxClipFrame
        var clipRect = clipBoxFrame
        
        if clipRect.width < CGFloat.ulpOfOne || clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let scale = min(maxClipRect.width / clipRect.width, maxClipRect.height / clipRect.height)
        
        let focusPoint = CGPoint(x: clipRect.midX, y: clipRect.midY)
        let midPoint = CGPoint(x: maxClipRect.midX, y: maxClipRect.midY)
        
        clipRect.size.width = ceil(clipRect.width * scale)
        clipRect.size.height = ceil(clipRect.height * scale)
        clipRect.origin.x = maxClipRect.minX + ceil((maxClipRect.width - clipRect.width) / 2)
        clipRect.origin.y = maxClipRect.minY + ceil((maxClipRect.height - clipRect.height) / 2)
        
        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = (focusPoint.x + scrollView.contentOffset.x) * scale
        contentTargetPoint.y = (focusPoint.y + scrollView.contentOffset.y) * scale
        
        var offset = CGPoint(x: contentTargetPoint.x - midPoint.x, y: contentTargetPoint.y - midPoint.y)
        offset.x = max(-clipRect.minX, offset.x)
        offset.y = max(-clipRect.minY, offset.y)
        UIView.animate(withDuration: 0.3) {
            if scale < 1 - CGFloat.ulpOfOne || scale > 1 + CGFloat.ulpOfOne {
                self.scrollView.zoomScale *= scale
                self.scrollView.zoomScale = min(self.scrollView.maximumZoomScale, self.scrollView.zoomScale)
            }

            if self.scrollView.zoomScale < self.scrollView.maximumZoomScale - CGFloat.ulpOfOne {
                offset.x = min(self.scrollView.contentSize.width - clipRect.maxX, offset.x)
                offset.y = min(self.scrollView.contentSize.height - clipRect.maxY, offset.y)
                self.scrollView.contentOffset = offset
            }
            self.clipActionToolView.alpha = 1
            self.dimView.alpha = 1
            self.changeClipBoxFrame(newFrame: clipRect)
        }
    }
    
    func clipImage() -> (clipImage: UIImage, editRect: CGRect) {
        let frame = convertClipRectToEditImageRect()
        let clipImage = editImage.he.clipImage(angle: 0, editRect: frame, isCircle: selectedRatio.isCircle) ?? editImage
        return (clipImage, frame)
    }
    
    func convertClipRectToEditImageRect() -> CGRect {
        let imageSize = editImage.size
        let contentSize = scrollView.contentSize
        let offset = scrollView.contentOffset
        let insets = scrollView.contentInset
        let realImageWRatio = imageSize.width / contentSize.width
        let realImageHRatio = imageSize.height / contentSize.height
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * realImageWRatio)
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * realImageHRatio)
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(clipBoxFrame.width * realImageWRatio)
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(clipBoxFrame.height * realImageHRatio)
        frame.size.height = min(imageSize.height, frame.height)
        
        return frame
    }
}

extension HEClipImageViewController: HEClipToolViewDelegate {
    func clipRatioSelected(sender: HEClipActionToolView, ratio: HEImageClipRatio) {
        self.clip(ratio: ratio)
    }
    
    func clipRotateSelected(sender: HEClipActionToolView) {
        self.rotate()
    }
}

extension HEClipImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == gridPanGes else {
            return true
        }
        // 그리드 드래그 제스쳐
        let point = gestureRecognizer.location(in: view)
        let frame = gridView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
}



extension HEClipImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        startEditing()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        startTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == self.scrollView else {
            return
        }
        if !decelerate {
            startTimer()
        }
    }
}

extension HEClipImageViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HEClipImageDismissAnimatedTransition()
    }
}

class HEClipShadowView: UIView {
    var clearRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor(white: 0, alpha: 0.7).setFill()
        UIRectFill(rect)
        let cr = clearRect.intersection(rect)
        UIColor.clear.setFill()
        UIRectFill(cr)
    }
}

// MARK: 자르기 오버레이 뷰

class HEClipGridView: UIView {
    
    static let cornerLineWidth: CGFloat = 4
    let cornerLineColor: CGColor = UIColor.he.rgba(71.0, 120.0, 222.0).cgColor
    
    var isCircle = false {
        didSet {
            guard oldValue != isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    var isEditing = false {
        didSet {
            guard isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1)
        context.beginPath()
        
        if isCircle {
            let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            let radius = rect.width / 2 - HEClipGridView.cornerLineWidth
            if !isEditing {
                // top left
                context.move(to: CGPoint(x: HEClipGridView.cornerLineWidth, y: HEClipGridView.cornerLineWidth))
                context.addLine(to: CGPoint(x: rect.width / 2, y: rect.origin.y + 3))
                context.addArc(center: center, radius: radius, startAngle: .pi * 1.5, endAngle: .pi, clockwise: true)
                context.closePath()
                
                // top right
                context.move(to: CGPoint(x: rect.width - HEClipGridView.cornerLineWidth, y: HEClipGridView.cornerLineWidth))
                context.addLine(to: CGPoint(x: rect.width - HEClipGridView.cornerLineWidth, y: rect.height / 2))
                context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 1.5, clockwise: true)
                context.closePath()
                
                // bottom left
                context.move(to: CGPoint(x: HEClipGridView.cornerLineWidth, y: rect.height - HEClipGridView.cornerLineWidth))
                context.addLine(to: CGPoint(x: HEClipGridView.cornerLineWidth, y: rect.height / 2))
                context.addArc(center: center, radius: radius, startAngle: .pi, endAngle: .pi / 2, clockwise: true)
                context.closePath()
                
                // bottom right
                context.move(to: CGPoint(x: rect.width - HEClipGridView.cornerLineWidth, y: rect.height - HEClipGridView.cornerLineWidth))
                context.addLine(to: CGPoint(x: rect.width / 2, y: rect.height - HEClipGridView.cornerLineWidth))
                context.addArc(center: center, radius: radius, startAngle: .pi / 2, endAngle: 0, clockwise: true)
                context.closePath()
                
                context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
                context.fillPath()
            }
            
            context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        }
        
        let circleDiff: CGFloat = (3 - 2 * sqrt(2)) * (rect.width - 2 * HEClipGridView.cornerLineWidth) / 6
        
        var dw: CGFloat = 1
        let spanw = (rect.size.width - 2) / 3
        for i in 0..<4 { // 세로선
            let isInnerLine = isCircle && 1...2 ~= i
            context.move(to: CGPoint(x: rect.origin.x + dw, y: (isInnerLine ? circleDiff : 0) + 1))
            context.addLine(to: CGPoint(x: rect.origin.x + dw,
                                        y: rect.height - (isInnerLine ? circleDiff : 0) - 1))
            dw += spanw
        }

        var dh: CGFloat = 1
        let spanh = (rect.size.height - 2) / 3
        for i in 0..<4 { // 가로선
            let isInnerLine = isCircle && 1...2 ~= i
            context.move(to: CGPoint(x: (isInnerLine ? circleDiff : 0) + 1, y: rect.origin.y + dh))
            context.addLine(to: CGPoint(x: rect.width - (isInnerLine ? circleDiff : 0) - 1, y: rect.origin.y + dh))
            dh += spanh
        }

        context.strokePath()
        
        
        context.setStrokeColor(cornerLineColor)
        context.setLineWidth(HEClipGridView.cornerLineWidth)
        let boldLineHalfThickness: CGFloat = HEClipGridView.cornerLineWidth / 2
        let boldLineLength: CGFloat = 20
        // 좌상
        context.move(to: CGPoint(x: 0, y: boldLineHalfThickness))
        context.addLine(to: CGPoint(x: boldLineLength, y: boldLineHalfThickness))

        context.move(to: CGPoint(x: boldLineHalfThickness, y: 0))
        context.addLine(to: CGPoint(x: boldLineHalfThickness, y: boldLineLength))

        // 우상
        context.move(to: CGPoint(x: rect.width - boldLineLength, y: boldLineHalfThickness))
        context.addLine(to: CGPoint(x: rect.width, y: boldLineHalfThickness))

        context.move(to: CGPoint(x: rect.width - boldLineHalfThickness, y: 0))
        context.addLine(to: CGPoint(x: rect.width - boldLineHalfThickness, y: boldLineLength))

        // 좌하
        context.move(to: CGPoint(x: boldLineHalfThickness, y: rect.height - boldLineLength))
        context.addLine(to: CGPoint(x: boldLineHalfThickness, y: rect.height))

        context.move(to: CGPoint(x: 0, y: rect.height - boldLineHalfThickness))
        context.addLine(to: CGPoint(x: boldLineLength, y: rect.height - boldLineHalfThickness))

        // 우하
        context.move(to: CGPoint(x: rect.width - boldLineLength, y: rect.height - boldLineHalfThickness))
        context.addLine(to: CGPoint(x: rect.width, y: rect.height - boldLineHalfThickness))

        context.move(to: CGPoint(x: rect.width - boldLineHalfThickness, y: rect.height - boldLineLength))
        context.addLine(to: CGPoint(x: rect.width - boldLineHalfThickness, y: rect.height))

        context.strokePath()

        context.setShadow(offset: CGSize(width: 1, height: 1), blur: 0)
    }
}
