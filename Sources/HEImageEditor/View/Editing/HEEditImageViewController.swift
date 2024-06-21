//
//  ZLEditImageViewController.swift
//  HEImageEditor
//

import UIKit

public typealias HEEditImageBottomToolViewBuilder = (HEEditImageView) -> (toolView: HEEditImageBottomToolView, height: CGFloat)

public typealias HEEditImageTopToolViewBuilder = (HEEditImageView) -> (toolView: HETopBarView, height: CGFloat)

open class HEEditImageViewController: UIViewController, HEEditImageView {
    static let maxDrawLineImageWidth: CGFloat = 600
    
    static let shadowColorFrom = UIColor.black.withAlphaComponent(0.35).cgColor
    
    static let shadowColorTo = UIColor.clear.cgColor
    
    public var drawColViewH: CGFloat = 50
    /// 필터 컬렉션 트레이 높이
    public var filterColViewH: CGFloat = 90
    
    public var adjustColViewH: CGFloat = 60
    
    public var trashbinSize = CGSize(width: 56, height: 56)
    
    /// 메인 컨테이터 뷰
    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()
    
    /// 메인 스크롤뷰의 컨텐츠 뷰
    ///
    /// - 여기에 이미지, 스티커 등 뷰가 포함
    /// - frame이 화면 중앙, clipStatus.editSize 를 따름
    open lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    // Showing image.
    open lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()
    
    private var topBarView: HETopBarView?
    private var topBarViewHeight: CGFloat = 0
    
    private lazy var topShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [HEEditImageViewController.shadowColorFrom, HEEditImageViewController.shadowColorTo]
        layer.locations = [0, 1]
        return layer
    }()
     
    /// 하단 툴바 영역
    private lazy var bottomToolViewContainer: HEPassThroughView = {
        let shadowView = HEPassThroughView()
        shadowView.findResponderSticker = { [weak self] point in
            return self?.findResponderSticker(point)
        }
        return shadowView
    }()
    
    private lazy var bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [HEEditImageViewController.shadowColorTo, HEEditImageViewController.shadowColorFrom]
        layer.locations = [0, 1]
        return layer
    }()
    
    private weak var bottomToolView: HEEditImageBottomToolView!
    private var bottomToolViewHeight: CGFloat!
    
    private var imageStickerTray: (UIView & HEImageStickerTray)? {
        HEImageEditorConfiguration.default().imageStickerTray
    }
    
    open var drawColorCollectionView: UICollectionView?
    open var filterCollectionView: UICollectionView?
    open var adjustCollectionView: UICollectionView?
    private lazy var loadingView = LoadingView()
    private var actionListeners: [any HEEditorActionListener] = []
    
    
    open lazy var eraserBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setImage(UIImage(systemName: "eraser"), for: .normal)
        btn.addTarget(self, action: #selector(eraserBtnClick), for: .touchUpInside)
        btn.isHidden = true
        btn.layer.cornerRadius = 18
        btn.layer.masksToBounds = true
        return btn
    }()
    
    open lazy var eraserBtnBgBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.isHidden = true
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
        return view
    }()
    
    open lazy var eraserLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .he.rgba(89, 95, 107, 0.8)
        view.isHidden = true
        return view
    }()
    
    open lazy var eraserCircleView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "eraser"))
        iv.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        iv.isHidden = true
        return iv
    }()

    open lazy var trashbinView: UIView = {
        let view = UIView()
        view.backgroundColor = .he.trashbinNormalBgColor
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    open lazy var trashbinImgView: UIImageView = {
        UIImageView(image: .he.getImage("ic_delete") ?? UIImage(systemName: "trash"))
    }()
    
    var adjustSlider: HEAdjustSlider?
    
    var animateDismiss = true
    
    var originalImage: UIImage
    
    // The frame after first layout, used in dismiss animation.
    /// self.view 좌표계에서 containerView 프레임
    var originalFrame: CGRect = .zero
    
    let tools: [HEImageEditorConfiguration.EditTool]
    
    let adjustTools: [HEImageEditorConfiguration.AdjustTool]
    
    var editImage: UIImage
    
    var editImageWithoutAdjust: UIImage
    
    var editImageAdjustRef: UIImage?
    
    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// 텍스트, 이미지 스티커 컨테이너
    private lazy var stickersContainer = UIView()
    /// 모자이크 스티커의 이동 중에만 활용
    private lazy var mosaicStickerActiveContainer = UIView()
    
    /// 모자이크 된 이미지
    private var mosaicImage: UIImage?
    /// mosaicImage 표시 레이어
    private lazy var mosaicImageLayer = CALayer()
    /// mosaicImageLayer 마스킹 레이어 - 제스쳐가 동작하는 동안 활용
    private lazy var mosaicImageLayerMaskLayer = CAShapeLayer()
    private var mosaicDrawPaths: [HEMosaicPath]
    private var mosaicDrawLineWidth: CGFloat = 25
    
    private var mosaicStickers: [HEImageStickerView] {
        stickersContainer.subviews.compactMap({
            if let v = $0 as? HEImageStickerView, v.kind == .mosaic {
                return v
            }
            return nil
        })
    }
    
    private lazy var aiStickerToastView: UIView = {
        let bt = UIButton()
        bt.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        bt.layer.cornerRadius = 16
        let icon = UIImage.he.getImage("editStickerFaceAi24") ?? UIImage(systemName: "faceid", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular, scale: .small))
        bt.setImage(icon, for: .normal)
        bt.setTitle("버튼을 누를 때마다 스티커가 바뀝니다.", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 14)
        bt.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        bt.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40 + 2)
        bt.adjustsImageWhenHighlighted = false
        return bt
    }()
    
    private var selectedTool: HEImageEditorConfiguration.EditTool? {
        didSet {
            if selectedTool == nil {
                bottomToolView.unselectTool()
            }
        }
    }
    
    private var selectedAdjustTool: HEImageEditorConfiguration.AdjustTool?
    private let drawColors: [UIColor]
    private var currentDrawColor = HEImageEditorConfiguration.default().defaultDrawColor
    private var drawPaths: [HEDrawPath]
    private var drawLineWidth: CGFloat = 6
    private var thumbnailFilterImages: [UIImage] = []
    
    // Cache the filter image of original image
    private var filterImages: [String: UIImage] = [:]
    
    private var currentFilter: HEFilter
    
    private var currentEditController: UIViewController?
    private var isScrolling = false
    private var shouldLayout = true
    private var imageStickerContainerIsHidden = true
    private var initialStickers: [HEBaseStickerView]
    private var currentClipStatus: HEClipStatus
    private var preClipStatus: HEClipStatus
    private var preStickerState: HEStickerEffect?
    private var currentAdjustStatus: HEAdjustStatus
    private var preAdjustStatus: HEAdjustStatus
    private var actionManager: HEEditorActionManager
    private lazy var deleteDrawPaths: [HEDrawPath] = []
    private var defaultDrawPathWidth: CGFloat = 0
    private var impactFeedback: UIImpactFeedbackGenerator?
    
    private lazy var drawPanGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    /// 이미지 너비와 높이의 교환 허용 여부
    private var shouldSwapSize: Bool {
        currentClipStatus.angle.he.toPi.truncatingRemainder(dividingBy: .pi) != 0
    }
    
    private var imageSize: CGSize {
        if shouldSwapSize {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        } else {
            return originalImage.size
        }
    }
    
    private var toolViewStateTimer: Timer?
    
    private var hasAdjustedImage = false
    // 편집 종료 TODO: Change to delegate
    @objc public var editFinishBlock: ((UIImage, HEEditImageModel?) -> Void)?
    
    /// 뷰 컨트롤러를 담는 뷰
    private lazy var childVCContainer = UIView()
    
    /// 선택된 편집 상태에서 사용하는 탑뷰
    private lazy var editingTopView = HETopConfirmBarView()
    
    /// 자르기 화면의 하단에 무언가 놓을 수 있다.. (없애버릴까..)
    public var clipImageBottomViewBuilder: HEClipImageBottomViewBuilder?
    /// 하단 툴뷰 구성자
    private var bottomToolViewBuilder: HEEditImageBottomToolViewBuilder!
    
    override open var prefersStatusBarHidden: Bool { true }
    
    override open var prefersHomeIndicatorAutoHidden: Bool { true }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    deinit {
        cleanToolViewStateTimer()
        trace()
    }
    
    /// 에디터 시작 팩토리 함수
    ///
    public class func showImageEditor(
        parent: UIViewController,
        animate: Bool = true,
        image: UIImage,
        editModel: HEEditImageModel? = nil,
        topToolViewBuilder: HEEditImageTopToolViewBuilder? = nil,
        bottomToolViewBuilder: HEEditImageBottomToolViewBuilder? = nil,
        clipImageBottomViewBuilder: HEClipImageBottomViewBuilder? = nil,
        completion: ((UIImage, HEEditImageModel?) -> Void)?
    ) {
        let vc = HEEditImageViewController(image: image, editModel: editModel, topToolViewBuilder: topToolViewBuilder, bottomToolViewBuilder: bottomToolViewBuilder)
        vc.clipImageBottomViewBuilder = clipImageBottomViewBuilder
        vc.editFinishBlock = { ei, editImageModel in
            completion?(ei, editImageModel)
        }
        vc.animateDismiss = animate
        vc.modalPresentationStyle = .overFullScreen
        parent.present(vc, animated: animate, completion: nil)
    }
    
    /// 에디터 생성
    public init(image: UIImage, 
                editModel: HEEditImageModel? = nil,
                topToolViewBuilder: HEEditImageTopToolViewBuilder? = nil,
                bottomToolViewBuilder: HEEditImageBottomToolViewBuilder? = nil) {
        var image = image
        if image.scale != 1,
           let cgImage = image.cgImage {
            image = image.he.resize_vI(
                CGSize(width: cgImage.width, height: cgImage.height),
                scale: 1
            ) ?? image
        }
        
        originalImage = image.he.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        currentClipStatus = editModel?.clipStatus ?? HEClipStatus(editRect: CGRect(origin: .zero, size: image.size))
        preClipStatus = currentClipStatus
        drawColors = HEImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicDrawPaths = editModel?.mosaicPaths ?? []
        currentAdjustStatus = editModel?.adjustStatus ?? HEAdjustStatus()
        preAdjustStatus = currentAdjustStatus
        
        var ts = HEImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), HEImageEditorConfiguration.default().imageStickerTray == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = HEImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first
        actionManager = HEEditorActionManager(actions: editModel?.actions ?? [])
        
        
        
        initialStickers = editModel?.stickers.compactMap {
            HEBaseStickerView.initWithState($0)
        } ?? []
        
        super.init(nibName: nil, bundle: nil)
        
        self.bottomToolViewBuilder = bottomToolViewBuilder ?? { editView in
            // 기본 툴바
            let toolbar = HEEditImageBottomToolView(tools: ts)
            toolbar.toolSelectListener = { [weak editView] type in
                guard let editView else { return }
                if editView.isImageEditing {
                    editView.stopCurrentEditing()
                    return
                }
                switch type {
                case .draw:
                    editView.startDrawing()
                case .clip:
                    editView.startClipping()
                case .imageSticker:
                    editView.startImageSticker()
                case .textSticker:
                    editView.startTextSticker()
                case .mosaicDraw:
                    editView.startMosaicDrawing()
                case .filter:
                    editView.startFiltering()
                case .adjust:
                    editView.startAdjusting()
                }
            }
            return (toolbar, 76)
        }
        
        if let builder = topToolViewBuilder?(self) {
            self.topBarView = builder.toolView
            self.topBarViewHeight = builder.height
        }
        
        actionManager.delegate = self
        
        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        rotationImageView()
        
        if tools.contains(.filter) {
            generateFilterImages()
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard tools.contains(.draw) else { return }
        
        var size = drawingImageView.frame.size
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }
        
        shouldLayout = false
        trace("edit image layout subviews")
        let insets = self.view.safeAreaInsets
        
        mainScrollView.frame = view.bounds
        resetContainerViewFrame()
        
        if let topBarView {
            topBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top + topBarViewHeight)
            topShadowLayer.frame = topBarView.bounds
        }
        
        bottomToolViewContainer.frame = CGRect(x: 0,
                                        y: view.frame.height - bottomToolViewHeight - insets.bottom,
                                        width: view.he.width,
                                        height: bottomToolViewHeight + insets.bottom)
        bottomShadowLayer.frame = bottomToolViewContainer.bounds
        
        eraserBtn.frame = CGRect(x: 20, y: 30 + (drawColViewH - 36) / 2, width: 36, height: 36)
        eraserBtnBgBlurView.frame = eraserBtn.frame
        eraserLineView.frame = CGRect(x: eraserBtn.he.right + 11, y: eraserBtn.frame.midY - 10, width: 1, height: 20)
        drawColorCollectionView?.frame = CGRect(x: eraserLineView.he.right + 11, y: 30, width: view.he.width - eraserLineView.he.right - 31, height: drawColViewH)
        
        adjustCollectionView?.frame = CGRect(x: 20, y: 20, width: view.he.width - 40, height: adjustColViewH)
        if HEImageEditorUIConfiguration.default().adjustSliderType == .vertical {
            adjustSlider?.frame = CGRect(x: view.he.width - 60, y: view.he.height / 2 - 100, width: 60, height: 200)
        } else {
            let sliderHeight: CGFloat = 60
            let sliderWidth = UIDevice.current.userInterfaceIdiom == .phone ? view.he.width - 100 : view.he.width / 2
            adjustSlider?.frame = CGRect(
                x: (view.he.width - sliderWidth) / 2,
                y: bottomToolViewContainer.he.top - sliderHeight,
                width: sliderWidth,
                height: sliderHeight
            )
        }
        
        filterCollectionView?.frame = CGRect(x: 20, y: 0, width: view.he.width - 40, height: filterColViewH)
         
        trashbinView.frame = CGRect(
            x: (view.he.width - trashbinSize.width) / 2,
            y: currentClipStatus.editRect.maxY - trashbinSize.height + 18,
            width: trashbinSize.width,
            height: trashbinSize.height
        )
        trashbinImgView.frame = CGRect(x: (trashbinSize.width - 24) / 2, y: (trashbinSize.height - 24) / 2, width: 24, height: 24)
        
        bottomToolView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: bottomToolViewHeight)
        childVCContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: bottomToolViewContainer.frame.minY)
        editingTopView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 48 + insets.top)
        
        if !drawPaths.isEmpty {
            drawLine()
        }
        if !mosaicDrawPaths.isEmpty || !mosaicStickers.isEmpty {
            generateNewMosaicImage()
        }
        
        if let index = drawColors.firstIndex(where: { $0 == self.currentDrawColor }) {
            drawColorCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    // MARK: --- lifecycle --
    
    public func addActionChangedListener<T: HEEditorActionListener>(_ listener: T) {
        actionListeners.append(listener)
        
    }
    public func removeActionChangedListener<T: HEEditorActionListener>(_ listener: T) {
        actionListeners.removeAll { ($0 as? T) == listener }
    }
    
    public func clearAllActionChangedListeners() {
        actionListeners.removeAll()
    }
    
    func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.he.resize(size) ?? originalImage
        
        DispatchQueue.global().async {
            self.thumbnailFilterImages = HEImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }
            
            DispatchQueue.main.async {
                self.filterCollectionView?.reloadData()
                self.filterCollectionView?.performBatchUpdates {} completion: { _ in
                    if let index = HEImageEditorConfiguration.default().filters.firstIndex(where: { $0 == self.currentFilter }) {
                        self.filterCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }
    
    func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage
        let editRect = currentClipStatus.editRect
        
        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        // editSize 를 화면에 맞춰 중앙에 위치
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2),
                                     y: max(0, (scrollViewSize.height - h) / 2),
                                     width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        
        if currentClipStatus.ratio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {
            containerView.layer.mask = nil
        }
        
        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        
        mosaicImageLayer.frame = imageView.bounds
        mosaicImageLayerMaskLayer.frame = imageView.bounds
        
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame
        mosaicStickerActiveContainer.frame = imageView.frame
        
        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }
        
        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(childVCContainer)
        
        // 메인 컨텐츠
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)
        containerView.addSubview(stickersContainer)
        containerView.addSubview(mosaicStickerActiveContainer)
        mosaicStickerActiveContainer.isHidden = true
        
        // 상단 툴바
        if let topBarView {
            view.addSubview(topBarView)
            topBarView.layer.addSublayer(topShadowLayer)
        }
        
        // 편집용 상단 툴바
        view.addSubview(editingTopView)
        editingTopView.hide(animate: false)
        
        // 하단 툴바
        view.addSubview(bottomToolViewContainer)
        let builder = self.bottomToolViewBuilder(self)
        bottomToolView = builder.toolView
        bottomToolViewHeight = builder.height
        bottomToolViewContainer.layer.addSublayer(bottomShadowLayer)
        bottomToolViewContainer.addSubview(bottomToolView)
        
        if tools.contains(.draw) {
            bottomToolViewContainer.addSubview(eraserBtnBgBlurView)
            bottomToolViewContainer.addSubview(eraserBtn)
            bottomToolViewContainer.addSubview(eraserLineView)
            containerView.addSubview(eraserCircleView)
            
            impactFeedback = UIImpactFeedbackGenerator(style: .light)

            let drawColorLayout = UICollectionViewFlowLayout()
            let drawColorItemWidth: CGFloat = 36
            drawColorLayout.itemSize = CGSize(width: drawColorItemWidth, height: drawColorItemWidth)
            drawColorLayout.minimumLineSpacing = 0
            drawColorLayout.minimumInteritemSpacing = 0
            drawColorLayout.scrollDirection = .horizontal
            let drawColorTopBottomInset = (drawColViewH - drawColorItemWidth) / 2
            drawColorLayout.sectionInset = UIEdgeInsets(top: drawColorTopBottomInset, left: 0, bottom: drawColorTopBottomInset, right: 0)
            
            let drawCV = UICollectionView(frame: .zero, collectionViewLayout: drawColorLayout)
            drawCV.backgroundColor = .clear
            drawCV.delegate = self
            drawCV.dataSource = self
            drawCV.isHidden = true
            bottomToolViewContainer.addSubview(drawCV)
            
            HEDrawColorCell.he.register(drawCV)
            drawColorCollectionView = drawCV
        }
        
        if tools.contains(.filter) {
            if let applier = currentFilter.applier {
                let image = applier(originalImage)
                editImage = image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
            
            let filterLayout = UICollectionViewFlowLayout()
            filterLayout.itemSize = CGSize(width: filterColViewH - 30, height: filterColViewH - 10)
            filterLayout.minimumLineSpacing = 15
            filterLayout.minimumInteritemSpacing = 15
            filterLayout.scrollDirection = .horizontal
            filterLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            
            let filterCV = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
            filterCV.backgroundColor = .clear
            filterCV.delegate = self
            filterCV.dataSource = self
            filterCV.isHidden = true
            bottomToolViewContainer.addSubview(filterCV)
            
            HEFilterImageCell.he.register(filterCV)
            filterCollectionView = filterCV
        }
        
        if tools.contains(.adjust) {
            editImage = editImage.he.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? editImage
            
            let adjustLayout = UICollectionViewFlowLayout()
            adjustLayout.itemSize = CGSize(width: adjustColViewH, height: adjustColViewH)
            adjustLayout.minimumLineSpacing = 10
            adjustLayout.minimumInteritemSpacing = 10
            adjustLayout.scrollDirection = .horizontal
            
            let adjustCV = UICollectionView(frame: .zero, collectionViewLayout: adjustLayout)
            adjustCV.backgroundColor = .clear
            adjustCV.delegate = self
            adjustCV.dataSource = self
            adjustCV.isHidden = true
            adjustCV.showsHorizontalScrollIndicator = false
            bottomToolViewContainer.addSubview(adjustCV)
            
            HEAdjustToolCell.he.register(adjustCV)
            adjustCollectionView = adjustCV
            
            adjustSlider = HEAdjustSlider()
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }
            adjustSlider?.beginAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.preAdjustStatus = self.currentAdjustStatus
            }
            adjustSlider?.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider?.endAdjust = { [weak self] in
                guard let self else { return }
                self.actionManager.storeAction(
                    .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
                )
                self.hasAdjustedImage = true
            }
            adjustSlider?.isHidden = true
            view.addSubview(adjustSlider!)
        }
        
        view.addSubview(trashbinView)
        trashbinView.addSubview(trashbinImgView)
        
        if hasMosaicFeatures() {
            mosaicImage = editImage.he.mosaicImage()
            mosaicImageLayer.contents = mosaicImage?.cgImage
            imageView.layer.addSublayer(mosaicImageLayer)
            imageView.layer.addSublayer(mosaicImageLayerMaskLayer)
            mosaicImageLayer.mask = mosaicImageLayerMaskLayer
        }
        
//        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
//        tapGes.delegate = self
//        view.addGestureRecognizer(tapGes)
        
        view.addGestureRecognizer(drawPanGes)
        mainScrollView.panGestureRecognizer.require(toFail: drawPanGes)
        
        initialStickers.forEach { self.attachSticker($0) }
        (aiStickerToastView as? UIButton)?.addTarget(self, action: #selector(hideAiStickerToast), for: .touchUpInside)
    }
    
    /// point로 스티커 찾기
    ///
    /// - point 는 컨트롤러의 view 좌표계
    private func findResponderSticker(_ point: CGPoint) -> UIView? {
        for sticker in stickersContainer.subviews.reversed() {
            let rect = stickersContainer.convert(sticker.frame, to: view)
            if rect.contains(point) {
                return sticker
            }
        }
        
        return nil
    }
    
    /// 회전 -
    ///
    /// -- TODO: 패튼 처리
    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: currentClipStatus.angle.he.toPi)
        imageView.transform = transform
        drawingImageView.transform = transform
        stickersContainer.transform = transform
    }
    
    public func cancel() {
        dismiss(animated: animateDismiss, completion: nil)
    }
    
    public var isImageEditing: Bool {
        return self.currentEditController != nil || self.selectedTool != nil
    }
    
    private var isInSubEditController: Bool {
        self.currentEditController != nil
    }
    
    @objc private func eraserBtnClick() {
        switchEraserBtnStatus(!eraserBtn.isSelected)
    }
    
    private func switchEraserBtnStatus(_ isSelected: Bool, reloadData: Bool = true) {
        guard eraserBtn.isSelected != isSelected else { return }
        
        eraserBtn.isSelected = isSelected
        eraserBtnBgBlurView.isHidden = !isSelected
        
        if reloadData {
            drawColorCollectionView?.reloadData()
        }
    }
    
    public func stopCurrentEditing() {
        
        switch self.selectedTool {
        case .draw:
            break
        case .clip:
            break
        case .imageSticker:
            self.imageStickerTray?.hide()
            break
        case .textSticker:
            break
        case .mosaicDraw:
            break
        case .filter:
            break
        case .adjust:
            break
        case .none:
            break
        }
        self.selectedTool = nil
        
        guard let current = self.currentEditController else { return }
        // TODO: 브레이크
        if let vc = current as? HEClipImageViewController {
            vc.doneEdit()
        }
    }
    
    // MARK: 자르기 시작
    
    public func startClipping() {
        self.preClipStatus = self.currentClipStatus
        
        var currentEditImage = editImage
        autoreleasepool {
            currentEditImage = buildImage()
        }
        
        let vc = HEClipImageViewController(image: currentEditImage, 
                                           status: currentClipStatus,
                                           bottomViewBuilder: self.clipImageBottomViewBuilder)
        
        let rect = mainScrollView.convert(containerView.frame, to: view)
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.he
            .clipImage(
                angle: currentClipStatus.angle,
                editRect: currentClipStatus.editRect,
                isCircle: currentClipStatus.ratio?.isCircle ?? false
            )
        vc.clipDoneBlock = { [weak self] angle, editRect, selectRatio in
            guard let self else { return }
            
            self.clipImage(status: HEClipStatus(editRect: editRect, angle: angle, ratio: selectRatio))
            self.actionManager.storeAction(.clip(oldStatus: self.preClipStatus, newStatus: self.currentClipStatus))
        }
        
        vc.cancelClipBlock = { [weak self] in
            self?.resetContainerViewFrame()
        }
        vc.dismissCallback = { [weak self] in
            self?.removeEditController()
            self?.finishEditingDismissAnimate()
            self?.selectedTool = nil
        }
        
        self.addToEditController(vc)
        self.startAnimateInEditController()
        
        selectedTool = .clip
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    public func startDrawing() {
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
        } else {
            selectedTool = nil
        }
        
        setDrawViews(hidden: !isSelected)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    
    // MARK: -- 이미지 스티커 시작
    public func startImageSticker() {
        guard let imageStickerTray else { return }
        imageStickerTray.hideBlock = { [weak self] in
            guard let self else { return }
            if self.selectedTool == nil {
                self.setToolView(show: true)
            }
            self.hideAiStickerToast()
            self.editingTopView.hide()
            self.imageStickerContainerIsHidden = true
        }
        
        imageStickerTray.selectImageStickerBlock = { [weak self] image in
            self?.addImageStickerView(image)
        }
        
        let trayFrame = getImageStickerTrayFrame()
        imageStickerTray.show(in: view, frame: trayFrame)
        imageStickerContainerIsHidden = false
        selectedTool = .imageSticker
        editingTopView.show()
        editingTopView.confirmClickCallback = { [weak self] in
            self?.selectedTool = nil
            self?.imageStickerTray?.hide()
        }
        editingTopView.cancelClickCallback = {[weak self] in
            self?.selectedTool = nil
            self?.imageStickerTray?.hide()
        }
        
        
        setToolView(show: false)
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    // MARK: -- startTextSticker
    public func startTextSticker() {
        showInputTextVC(font: HEImageEditorConfiguration.default().textStickerDefaultFont)
        
        selectedTool = nil
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    public func startMosaicDrawing() {
        let isSelected = selectedTool != .mosaicDraw
        if isSelected {
            selectedTool = .mosaicDraw
        } else {
            selectedTool = nil
        }
        
        generateNewMosaicLayerIfAdjust()
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    public func startFiltering() {
        let isSelected = selectedTool != .filter
        if isSelected {
            selectedTool = .filter
        } else {
            selectedTool = nil
        }
        
        setDrawViews(hidden: true)
        setFilterViews(hidden: !isSelected)
        setAdjustViews(hidden: true)
    }
    
    public func startAdjusting() {
        let isSelected = selectedTool != .adjust
        if isSelected {
            selectedTool = .adjust
        } else {
            selectedTool = nil
        }
        
        generateAdjustImageRef()
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: !isSelected)
    }
    
    private func setDrawViews(hidden: Bool) {
        eraserBtn.isHidden = hidden
        eraserBtnBgBlurView.isHidden = hidden || !eraserBtn.isSelected
        eraserLineView.isHidden = hidden
        drawColorCollectionView?.isHidden = hidden
    }
    
    private func setFilterViews(hidden: Bool) {
        filterCollectionView?.isHidden = hidden
    }
    
    private func setAdjustViews(hidden: Bool) {
        adjustCollectionView?.isHidden = hidden
        adjustSlider?.isHidden = hidden
    }
    
    private func changeAdjustTool(_ tool: HEImageEditorConfiguration.AdjustTool) {
        selectedAdjustTool = tool
        
        switch tool {
        case .brightness:
            adjustSlider?.value = currentAdjustStatus.brightness
        case .contrast:
            adjustSlider?.value = currentAdjustStatus.contrast
        case .saturation:
            adjustSlider?.value = currentAdjustStatus.saturation
        }
    }
    
    @objc 
    public func done() {
        var stickerStates: [HEStickerEffect] = []
        for view in stickersContainer.subviews {
            guard let view = view as? HEBaseStickerView else { continue }
            stickerStates.append(view.state)
        }
        
        var hasEdit = true
        if drawPaths.isEmpty,
           currentClipStatus.editRect.size == imageSize,
           currentClipStatus.angle == 0,
           mosaicDrawPaths.isEmpty,
           stickerStates.isEmpty,
           currentFilter.applier == nil,
           currentAdjustStatus.allValueIsZero {
            hasEdit = false
        }
        
        var resImage = originalImage
        var editModel: HEEditImageModel?
        
        func callback() {
            dismiss(animated: animateDismiss) {
                self.editFinishBlock?(resImage, editModel)
            }
        }
        
        guard hasEdit else {
            callback()
            return
        }
        
        autoreleasepool {
            let hud = HEProgressHUD(style: HEImageEditorUIConfiguration.default().hudStyle)
            hud.show(in: view)
            
            DispatchQueue.main.async { [self] in
                resImage = buildImage()
                resImage = resImage.he
                    .clipImage(
                        angle: currentClipStatus.angle,
                        editRect: currentClipStatus.editRect,
                        isCircle: currentClipStatus.ratio?.isCircle ?? false
                    ) ?? resImage
                if let oriDataSize = originalImage.jpegData(compressionQuality: 1)?.count {
                    resImage = resImage.he.compress(to: oriDataSize)
                }
                
                editModel = HEEditImageModel(
                    drawPaths: drawPaths,
                    mosaicPaths: mosaicDrawPaths,
                    clipStatus: currentClipStatus,
                    adjustStatus: currentAdjustStatus,
                    selectFilter: currentFilter,
                    stickers: stickerStates,
                    actions: actionManager.actions
                )
                
                hud.hide()
                callback()
            }
        }
    }
    
    public func undo() {
        actionManager.undoAction()
    }
    
    public func redo() {
        actionManager.redoAction()
    }
    
    // MARK: 여기 아래는 대부분 내부 함수들 --
    
    private func addToEditController(_ target: UIViewController) {
        if let exist = self.currentEditController {
            exist.willMove(toParent: nil)
            exist.view.removeFromSuperview()
            exist.removeFromParent()
        }
        self.addChild(target)
        childVCContainer.addSubview(target.view)
        target.view.frame = childVCContainer.bounds
        target.didMove(toParent: self)
        self.currentEditController = target
    }
    
    private func removeEditController() {
        if let exist = self.currentEditController {
            exist.willMove(toParent: nil)
            exist.view.removeFromSuperview()
            exist.removeFromParent()
        }
        self.currentEditController = nil
    }
    
    
    private func clipImage(status: HEClipStatus) {
        let oldAngle = currentClipStatus.angle
        let oldContainerSize = stickersContainer.frame.size
        if oldAngle != status.angle {
            currentClipStatus.angle = status.angle
            rotationImageView()
        }
        
        currentClipStatus.editRect = status.editRect
        currentClipStatus.ratio = status.ratio
        resetContainerViewFrame()
        recalculateStickersFrame(oldContainerSize, oldAngle, status.angle)
    }
    
    
    // TODO: 제외
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        if bottomToolViewContainer.alpha == 1 {
            setToolView(show: false)
        } else {
            setToolView(show: true)
        }
    }
    
    /// 패닝 제스쳐를 드로잉 작업으로 처리
    @objc private func panGestureAction(_ pan: UIPanGestureRecognizer) {
        // 지우개
        if selectedTool == .draw, eraserBtn.isSelected {
            eraserGestureAction(pan)
            return
        }
        
        if selectedTool == .draw {
            drawAction(pan)
            
        } else if selectedTool == .mosaicDraw {
            drawWithMosaicAction(pan)
        }
    }
    
    private func drawWithMosaicAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: imageView)
        switch pan.state {
        case .began:
            setToolView(show: false)
            
            let ratio = getImagePresentingRatio()
            let pathW = mosaicDrawLineWidth / mainScrollView.zoomScale
            let hepath = HEMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
            
            mosaicImageLayerMaskLayer.fillColor = nil
            mosaicImageLayerMaskLayer.strokeColor = UIColor.black.cgColor
            mosaicImageLayerMaskLayer.lineWidth = pathW
            mosaicImageLayerMaskLayer.path = hepath.path.cgPath
            mosaicDrawPaths.append(hepath)
            
            imageView.layer.addSublayer(mosaicImageLayer)
            imageView.layer.insertSublayer(mosaicImageLayerMaskLayer, above: mosaicImageLayer)
            mosaicImageLayer.mask = mosaicImageLayerMaskLayer
            
        case .changed:
            let hepath = mosaicDrawPaths.last
            hepath?.addLine(to: point)
            mosaicImageLayerMaskLayer.path = hepath?.path.cgPath
            
        case .cancelled, .ended:
            setToolView(show: true, delay: 0.5)
            if let path = mosaicDrawPaths.last {
                actionManager.storeAction(.mosaic(path))
            }
            generateNewMosaicImage()
            mosaicImageLayerMaskLayer.path = nil
        default:
            break
        }
    }
    
    private func drawAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: drawingImageView)
        switch pan.state {
        case .began:
            setToolView(show: false)
            
            let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
            let ratio = min(
                mainScrollView.frame.width / currentClipStatus.editRect.width,
                mainScrollView.frame.height / currentClipStatus.editRect.height
            )
            let scale = ratio / originalRatio
            // Zoom to original size
            var size = drawingImageView.frame.size
            size.width /= scale
            size.height /= scale
            if shouldSwapSize {
                swap(&size.width, &size.height)
            }
            
            var toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.width
            if editImage.size.width / editImage.size.height > 1 {
                toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.height
            }
            
            let path = HEDrawPath(
                pathColor: currentDrawColor,
                pathWidth: drawLineWidth / mainScrollView.zoomScale,
                defaultLinePath: defaultDrawPathWidth,
                ratio: ratio / originalRatio / toImageScale,
                startPoint: point
            )

            drawPaths.append(path)
            
        case .changed:
            let path = drawPaths.last
            path?.addLine(to: point)
            drawLine()
            
        case .ended, .cancelled:
            setToolView(show: true, delay: 0.5)
            if let path = drawPaths.last {
                actionManager.storeAction(.draw(path))
            }
            
        default:
            break
        }
    }
    
    private func eraserGestureAction(_ pan: UIPanGestureRecognizer) {
        // DrawingImageView를 기준으로 한 점
        let point = pan.location(in: drawingImageView)
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // 원본 크기로 조정
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let pointScale = ratio / originalRatio / toImageScale
        // drawPath로 변환된 포인트
        let drawPoint = CGPoint(x: point.x / pointScale, y: point.y / pointScale)
        if pan.state == .began {
            eraserCircleView.isHidden = false
            impactFeedback?.prepare()
        }
        
        if pan.state == .began || pan.state == .changed {
            var transform: CGAffineTransform = .identity
            
            let angle = ((Int(currentClipStatus.angle) % 360) + 360) % 360
            let drawingImageViewSize = drawingImageView.frame.size
            if angle == 90 {
                transform = transform.translatedBy(x: 0, y: -drawingImageViewSize.width)
            } else if angle == 180 {
                transform = transform.translatedBy(x: -drawingImageViewSize.width, y: -drawingImageViewSize.height)
            } else if angle == 270 {
                transform = transform.translatedBy(x: -drawingImageViewSize.height, y: 0)
            }
            transform = transform.concatenating(drawingImageView.transform)
            eraserCircleView.center = point.applying(transform)
            
            var needDraw = false
            for path in drawPaths {
                if path.path.contains(drawPoint), !deleteDrawPaths.contains(path) {
                    path.willDelete = true
                    deleteDrawPaths.append(path)
                    needDraw = true
                    impactFeedback?.impactOccurred()
                }
            }
            if needDraw {
                drawLine()
            }
        } else {
            eraserCircleView.isHidden = true
            if !deleteDrawPaths.isEmpty {
                actionManager.storeAction(.eraser(deleteDrawPaths))
                drawPaths.removeAll { deleteDrawPaths.contains($0) }
                deleteDrawPaths.removeAll()
                drawLine()
            }
        }
    }
    
    // 매개변수를 조정하지 않고 이미지 생성
    private func generateAdjustImageRef() {
        editImageAdjustRef = generateNewMosaicImage(
            inputImage: editImageWithoutAdjust,
            inputMosaicImage: editImageWithoutAdjust.he.mosaicImage(),
            skipEditImage: true
        )
    }
    
    private func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool else {
            return
        }
        
        switch selectedAdjustTool {
        case .brightness:
            if currentAdjustStatus.brightness == value {
                return
            }
            
            currentAdjustStatus.brightness = value
        case .contrast:
            if currentAdjustStatus.contrast == value {
                return
            }
            
            currentAdjustStatus.contrast = value
        case .saturation:
            if currentAdjustStatus.saturation == value {
                return
            }
            
            currentAdjustStatus.saturation = value
        }
        
        adjustStatusChanged()
    }
    
    private func adjustStatusChanged() {
        let resultImage = editImageAdjustRef?.he.adjust(
            brightness: currentAdjustStatus.brightness,
            contrast: currentAdjustStatus.contrast,
            saturation: currentAdjustStatus.saturation
        )
        
        guard let resultImage else { return }
        
        editImage = resultImage
        imageView.image = editImage
    }
    
    private func hasMosaicFeatures() -> Bool {
        return tools.contains(.mosaicDraw) || (imageStickerTray?.hasMosaicSticker == true)
    }
    
    private func generateNewMosaicLayerIfAdjust() {
        defer {
            hasAdjustedImage = false
        }
        
        guard hasMosaicFeatures(), hasAdjustedImage else { return }
        generateNewMosaicImageLayer()
        
        if !mosaicDrawPaths.isEmpty || !mosaicStickers.isEmpty {
            generateNewMosaicImage()
        }
    }
    
    private func setToolView(show: Bool, delay: TimeInterval? = nil) {
        cleanToolViewStateTimer()
        if let delay = delay {
            toolViewStateTimer = Timer.scheduledTimer(timeInterval: delay, target: HEWeakProxy(target: self), selector: #selector(setToolViewShowInTimer(show:)), userInfo: ["show": show], repeats: false)
            RunLoop.current.add(toolViewStateTimer!, forMode: .common)
        } else {
            setToolViewShowInTimer(show: show)
        }
    }
    
    @objc private func setToolViewShowInTimer(show: Bool) {
        var flag = show
        if let toolViewStateTimer = toolViewStateTimer {
            let userInfo = toolViewStateTimer.userInfo as? [String: Any]
            flag = userInfo?["show"] as? Bool ?? true
            cleanToolViewStateTimer()
        }
        topBarView?.layer.removeAllAnimations()
        //bottomTabBarView.layer.removeAllAnimations()
        adjustSlider?.layer.removeAllAnimations()
        if flag {
            self.topBarView?.show()
            UIView.animate(withDuration: 0.25) {
                //self.bottomTabBarView.alpha = 1
                self.adjustSlider?.alpha = 1
            }
        } else {
            self.topBarView?.hide()
            UIView.animate(withDuration: 0.25) {
                //self.bottomTabBarView.alpha = 0
                self.adjustSlider?.alpha = 0
            }
        }
    }
    
    private func cleanToolViewStateTimer() {
        toolViewStateTimer?.invalidate()
        toolViewStateTimer = nil
    }
    
    private func showInputTextVC(stickerId: String? = nil,
                                 text: String? = nil,
                                 textColor: UIColor? = nil,
                                 fillColor: UIColor? = nil,
                                 font: UIFont? = nil) {
        var bgImage: UIImage?
        autoreleasepool {
            // Calculate image displayed frame on the screen.
            var r = mainScrollView.convert(view.frame, to: containerView)
            r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
            r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
            let scale = imageSize.width / imageView.frame.width
            r.origin.x *= scale
            r.origin.y *= scale
            r.size.width *= scale
            r.size.height *= scale
            
            let isCircle = currentClipStatus.ratio?.isCircle ?? false
            bgImage = buildImage()
                .he.clipImage(angle: currentClipStatus.angle, editRect: currentClipStatus.editRect, isCircle: isCircle)?
                .he.clipImage(angle: 0, editRect: r, isCircle: isCircle)
        }
        
        let vc = HEInputTextViewController(stickerId: stickerId, image: bgImage, text: text, font: font, textColor: textColor, fillColor: fillColor)
        vc.delegate = self
        
        vc.modalPresentationStyle = .fullScreen
        showDetailViewController(vc, sender: nil)
    }
    
    
    // TODO: 스티커 갯수 제한, 제스쳐 100 개 문제
    
    // MARK: 스티커를 뷰로 추가 --
    
    private func getImageStickerTrayFrame() -> CGRect {
        let trayFrame = CGRect(x: 0, y: bottomToolViewContainer.frame.minY - HEImageEditorLayout.imageStickerTrayHeight,
                               width: view.bounds.width,
                               height: HEImageEditorLayout.imageStickerTrayHeight)
        return trayFrame
    }
    
    private func showAiStickerToastIfNeed(stickerTrayFrame: CGRect) {
        guard aiStickerToastView.superview == nil else { return }
        view.addSubview(aiStickerToastView)
        aiStickerToastView.also { it in
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
        guard aiStickerToastView.superview != nil else {
            return
        }
        UIView.animate(withDuration: 0.24, delay: 0, animations: {
            self.aiStickerToastView.alpha = 0
        }, completion: { _ in
            self.aiStickerToastView.removeFromSuperview()
        })
    }
    
    /// 스티커를 뷰로 추가
    private func addImageStickerView(_ sticker: HEImageSticker) {
        if sticker.id == HEImageSticker.faceAiIcon.id {
            if loadingView.isShowing {
                return
            }
            addImageStickersOnFaces()
            showAiStickerToastIfNeed(stickerTrayFrame: getImageStickerTrayFrame())
            return
        }
        let image: UIImage = sticker.image
        let scale = mainScrollView.zoomScale
        let stickerViewSize = HEImageStickerView.constraintViewSize(image: image, container: view)
        let originFrame = getStickerOriginFrame(stickerViewSize)
        
        let imageSticker = HEImageStickerView(kind: sticker.kind,
                                              image: image,
                                              originScale: 1 / scale,
                                              originAngle: -currentClipStatus.angle,
                                              originFrame: originFrame)
        attachSticker(imageSticker)
        if sticker.kind == .mosaic {
            applyMosaicImageToStickerView(imageSticker)
        }
        view.layoutIfNeeded()
        
        actionManager.storeAction(.sticker(oldState: nil, newState: imageSticker.state))
    }
    
    private func addImageStickersOnFaces() {
        guard let imageStickerTray else {
            showAlert("스티커 사용 구성이 되지 않았습니다.")
            return
        }
        // 로딩 표시
        loadingView.show(inCenterOf: self.view)
        
        Task { @MainActor in
            do {
                for sticker in stickersContainer.subviews.reversed() {
                    if let stickerView = (sticker as? HEImageStickerView), stickerView.kind == .faceAI {
                        removeSticker(id: stickerView.id)
                    }
                }
                
                let results = try await HEFaceDetection().detect(from: editImage, orientation: editImage.imageOrientation)
                let animeDuration = TimeInterval(min(Double(results.count) * 2, 1.6))
                var i: Double = 0
                let count = Double(results.count)
                let halfPi = Double.pi / 2
                for result in results {
                    trace(result)
                    if let sticker = imageStickerTray.randomSticker(inSection: 0) {
                        let image = sticker.image
                        let scale = mainScrollView.zoomScale
                        // let size = HEImageStickerView.calculateSize(image: image, container: view)
                        let originFrame = getStickerOriginFrame(stickerFrame: result.frame)
                        let imageSticker = HEImageStickerView(
                            id: sticker.id,
                            kind: .faceAI,
                            image: image,
                            originScale: 1 / scale,
                            originAngle: -currentClipStatus.angle,
                            originFrame: originFrame,
                            gesRotation:  -CGFloat(result.roll ?? 0.0)
                        )
                        
                        let delay = sin(halfPi * i / count) * animeDuration
                        attachSticker(imageSticker, delay: delay)
                        // view.layoutIfNeeded()
                        
                        // 액션 저장
                        actionManager.storeAction(.sticker(oldState: nil, newState: imageSticker.state))
                        
                        i += 1.0
                    }
                }
                
                try? await Task.sleep(nanoseconds: animeDuration.nanoseconds)
                self.loadingView.hide()
                
            } catch {
                trace("Vision Error ----")
                trace(error)
            }
        }
    }
    
    /// 스티커의 스티커 컨테이너 내 영역을 구함
    ///
    /// - stickersContainer.frame 은 imageView.frame (clipStatus.editRect)과 동일
    private func getStickerOriginFrame(stickerFrame: CGRect) -> CGRect {
        let scale = mainScrollView.zoomScale
        let rr = imageView.frame.width / editImage.size.width
        let rw = stickerFrame.width * rr * scale
        let rh = stickerFrame.height * rr * scale
        let rx = stickerFrame.origin.x * rr + (stickerFrame.width * rr - rw) / 2
        let ry = stickerFrame.origin.y * rr + (stickerFrame.height * rr - rh) / 2
        let originFrame = CGRect(x: rx, y: ry, width: rw, height: rh)
        return originFrame
    }
    
    
    /// 스티커를 현재 화면 중앙에 위치
    private func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let y = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }
    
    private func clearMosaicImageFromStickerView(_ stickerView: HEImageStickerView) {
        let scale = (view.window?.windowScene?.screen.scale ?? 1.0)
        let startSide: CGFloat = 150 / scale // 150 pixel
        stickerView.setImage(UIImage().he.solid(.clear, width: startSide, height: startSide).he.circle())
    }
    
    private func applyMosaicImageToStickerView(_ stickerView: HEImageStickerView, withRatio ratio: CGFloat? = nil) {
        let presentingRatio = ratio ?? getImagePresentingRatio()
        var frame = stickerView.frame.insetBy(dx: HEImageStickerView.edgeInset, dy: HEImageStickerView.edgeInset)
        frame = CGRect(x: frame.minX / presentingRatio, y: frame.minY / presentingRatio, width: frame.width / presentingRatio, height: frame.height / presentingRatio)
        if let image = mosaicImage?.he.clipImage(angle: 0, editRect: frame, isCircle: true) {
            stickerView.setImage(image)
        }
    }
    /// ratio = 보여지는 영역 / 편집 이미지 영역
    private func getImagePresentingRatio() -> CGFloat {
        var actualSize = currentClipStatus.editRect.size
        if shouldSwapSize {
            swap(&actualSize.width, &actualSize.height)
        }
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        return ratio
    }
    
    /// Add text sticker
    private func addTextStickersView(_ text: String, textColor: UIColor, fillColor: UIColor, font: UIFont, image: UIImage?) {
        guard !text.isEmpty, let image = image else { return }
        
        let scale = mainScrollView.zoomScale
        let size = HETextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = HETextStickerView(
            text: text,
            textColor: textColor,
            fillColor: fillColor,
            font: font,
            image: image,
            originScale: 1 / scale,
            originAngle: -currentClipStatus.angle,
            originFrame: originFrame
        )
        attachSticker(textSticker)
        
        actionManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    
    private func attachSticker(_ sticker: HEBaseStickerView, delay: TimeInterval = 0) {
        trace("delay=\(delay)")
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        configSticker(sticker)
        
        if sticker.kind != .mosaic {
            let transform = sticker.originTransform.scaledBy(x: 1.4, y: 1.4)
            sticker.transform = transform
            sticker.alpha = 0
            UIView.animate(withDuration: 0.6, delay: delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.4) {
                sticker.alpha = 1
                sticker.transform = sticker.originTransform
            }
        }
    }
    
    private func removeSticker(id: String?) {
        guard let id else { return }
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerID = (sticker as? HEBaseStickerView)?.id,
                  stickerID == id else {
                continue
            }
            (sticker as? HEBaseStickerView)?.moveToTrashbin()
            break
        }
    }
    
    // TODO: 탭으로 선택한 스티커만 제스쳐 처리
    private func configSticker(_ sticker: HEBaseStickerView) {
        sticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
        drawPanGes.require(toFail: sticker.panGes)
    }
    
    private func recalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let currSize = stickersContainer.frame.size
        let scale: CGFloat
        if Int(newAngle - oldAngle) % 180 == 0 {
            scale = currSize.width / oldSize.width
        } else {
            scale = currSize.height / oldSize.width
        }
        
        stickersContainer.subviews.forEach { view in
            (view as? HEStickerViewAdditional)?.addScale(scale)
        }
    }
    
    private func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        var toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = HEEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        drawingImageView.image = UIGraphicsImageRenderer.he.renderImage(size: size) { context in
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for path in drawPaths {
                path.drawPath()
            }
        }
    }
    
    private func changeFilter(_ filter: HEFilter) {
        func adjustImage(_ image: UIImage) -> UIImage {
            guard tools.contains(.adjust), !currentAdjustStatus.allValueIsZero else {
                return image
            }
            
            return image.he.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? image
        }
        
        currentFilter = filter
        if let image = filterImages[currentFilter.name] {
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
        } else {
            let image = currentFilter.applier?(originalImage) ?? originalImage
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
            filterImages[currentFilter.name] = image
        }
        
        if hasMosaicFeatures() {
            generateNewMosaicImageLayer()
            
            if mosaicDrawPaths.isEmpty && mosaicStickers.isEmpty {
                imageView.image = editImage
            } else {
                generateNewMosaicImage()
            }
        } else {
            imageView.image = editImage
        }
    }
    
    /// editImage 의 모자이크 버전을 다시 생성
    func generateNewMosaicImageLayer() {
        mosaicImage = editImage.he.mosaicImage()
        mosaicImageLayer.removeFromSuperlayer()
        
        let mosaicImageLayer = CALayer()
        mosaicImageLayer.frame = imageView.bounds
        mosaicImageLayer.contents = mosaicImage?.cgImage
        imageView.layer.insertSublayer(mosaicImageLayer, below: mosaicImageLayerMaskLayer)
        
        mosaicImageLayer.mask = mosaicImageLayerMaskLayer
        
        self.mosaicImageLayer = mosaicImageLayer
    }
    
    /// 모자이크 이미지 생성 후 editImage, imageView 에 반영한다.
    ///
    /// - Parameters:
    ///   - inputImage: 원본 이미지 대신에 이 이미지에 대한 모자이크를 처리한다.
    ///   - inputMosaicImage: 기본 모자이크된 이미지 대신에 이 이미지를 사용된다.
    ///   - skipEditImage: editImage, imageView 에 반영하지 않고 생성된 모자이크된 이미지만 반환한다.
    /// - Returns: 새로 생성된 모자이크 이미지
    @discardableResult
    private func generateNewMosaicImage(inputImage: UIImage? = nil,
                                inputMosaicImage: UIImage? = nil,
                                skipEditImage: Bool = false) -> UIImage? {
        
//        var actualSize = currentClipStatus.editRect.size
//        if shouldSwapSize {
//            swap(&actualSize.width, &actualSize.height)
//        }
//        let ratio = min(
//            mainScrollView.frame.width / currentClipStatus.editRect.width,
//            mainScrollView.frame.height / currentClipStatus.editRect.height
//        )

        let renderRect = CGRect(origin: .zero, size: originalImage.size)
        var midImage = UIGraphicsImageRenderer.he.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { context in
            if inputImage != nil {
                inputImage?.draw(in: renderRect)
            } else {
                var drawImage: UIImage
                // 필터 적용
                if tools.contains(.filter), let image = filterImages[currentFilter.name] {
                    drawImage = image
                } else {
                    drawImage = originalImage
                }
                drawImage.draw(at: .zero)
                
                // CSB 적용
                if tools.contains(.adjust), !currentAdjustStatus.allValueIsZero {
                    drawImage = drawImage.he.adjust(
                        brightness: currentAdjustStatus.brightness,
                        contrast: currentAdjustStatus.contrast,
                        saturation: currentAdjustStatus.saturation
                    ) ?? drawImage
                }
                
                drawImage.draw(in: renderRect)
            }
            // 모자잌 패스로 지움
            mosaicDrawPaths.forEach { path in
                context.move(to: path.startPoint)
                path.linePoints.forEach { point in
                    context.addLine(to: point)
                }
                context.setLineWidth(path.path.lineWidth / path.ratio)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setBlendMode(.clear)
                context.strokePath()
            }
            // 모자잌 스티커로 지움
//            let stickers = self.mosaicStickers.filter({ !$0.onOperation })
//            stickers.forEach { v in
//                let frame = v.frame.insetBy(dx: HEImageStickerView.edgeInset, dy: HEImageStickerView.edgeInset)
//                context.addEllipse(in: CGRect(x: frame.minX / ratio,
//                                              y: frame.minY / ratio,
//                                              width: frame.width / ratio,
//                                              height: frame.height / ratio))
//                context.setLineWidth(0)
//                context.setBlendMode(.clear)
//                context.setFillColor(UIColor.blue.cgColor)
//                context.fillPath()
//            }
        }
        
        guard let midCgImage = midImage.cgImage else { return nil }
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        let temp = UIGraphicsImageRenderer.he.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { _ in
            // 생성된 모자이크 이미지는 가장자리 부분에 빈 부분이 있어 합성 후 가장자리가 검은색이 될 수 있으므로 하단에 원본 이미지를 먼저 그려줌.
            originalImage.draw(in: renderRect)
            (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
            midImage.draw(at: .zero)
        }
        
        guard let cgi = temp.cgImage else { return nil }
        let image = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
        
        if skipEditImage {
            return image
        }
        
        editImage = image
        imageView.image = image
        mosaicImageLayerMaskLayer.path = nil
        
        return image
    }
    
    private func buildImage() -> UIImage {
        let imageSize = originalImage.size
        
        let temp = UIGraphicsImageRenderer.he.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            editImage.draw(at: .zero)
            drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))
            
            if !stickersContainer.subviews.isEmpty {
                let scale = self.imageSize.width / stickersContainer.frame.width
                stickersContainer.subviews.forEach { view in
                    (view as? HEStickerViewAdditional)?.resetState()
                }
                context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                stickersContainer.layer.render(in: context)
                context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
            }
        }
        
        guard let cgi = temp.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }
    
    private func startAnimateInEditController() {
        self.topBarView?.hide()
        UIView.animate(withDuration: 0.2, animations: {
            self.adjustSlider?.alpha = 0
        }) { _ in
            self.mainScrollView.isHidden = true
            self.adjustSlider?.isHidden = true
            
        }
    }
    
    /// 편집 container 작업이 끝나면,
    ///
    /// - HEClipImageDismissAnimatedTransition 에서도 호출
    func finishEditingDismissAnimate() {
        mainScrollView.alpha = 1
        mainScrollView.isHidden = false
        adjustSlider?.alpha = 0
        adjustSlider?.isHidden = false
        topBarView?.show()
        UIView.animate(withDuration: 0.2, animations: {
            self.adjustSlider?.alpha = 1
        })
    }
}

extension HEEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard imageStickerContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomToolViewContainer.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                let convertP = bottomToolViewContainer.convert(p, from: view)
                for subview in bottomToolViewContainer.subviews {
                    if !subview.isHidden,
                       subview.alpha != 0,
                       subview.frame.contains(convertP) {
                        return false
                    }
                }
                return true
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = selectedTool else {
                return false
            }
            return (st == .draw || st == .mosaicDraw) && !isScrolling
        }
        
        return true
    }
}

// MARK: scroll view delegate

extension HEEditImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = true
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = decelerate
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
}

extension HEEditImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == drawColorCollectionView {
            return drawColors.count
        } else if collectionView == filterCollectionView {
            return thumbnailFilterImages.count
        } else {
            return adjustTools.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       if collectionView == drawColorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEDrawColorCell.he.identifier, for: indexPath) as! HEDrawColorCell
            
            let c = drawColors[indexPath.row]
            cell.color = c
            if c == currentDrawColor, !eraserBtn.isSelected {
                cell.colorView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
            } else {
                cell.colorView.layer.transform = CATransform3DIdentity
            }
            
            return cell
        } else if collectionView == filterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEFilterImageCell.he.identifier, for: indexPath) as! HEFilterImageCell
            
            let image = thumbnailFilterImages[indexPath.row]
            let filter = HEImageEditorConfiguration.default().filters[indexPath.row]
            
            cell.nameLabel.text = filter.name
            cell.imageView.image = image
            
            if currentFilter === filter {
                cell.nameLabel.textColor = .he.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .he.toolTitleNormalColor
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEAdjustToolCell.he.identifier, for: indexPath) as! HEAdjustToolCell
            
            let tool = adjustTools[indexPath.row]
            
            cell.imageView.isHighlighted = false
            cell.adjustTool = tool
            let isSelected = tool == selectedAdjustTool
            cell.imageView.isHighlighted = isSelected
            
            if isSelected {
                cell.nameLabel.textColor = .he.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .he.toolTitleNormalColor
            }
            
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == drawColorCollectionView {
            currentDrawColor = drawColors[indexPath.row]
            switchEraserBtnStatus(false, reloadData: false)
        } else if collectionView == filterCollectionView {
            let filter = HEImageEditorConfiguration.default().filters[indexPath.row]
            actionManager.storeAction(.filter(oldFilter: currentFilter, newFilter: filter))
            changeFilter(filter)
        } else { // adjust tools
            let tool = adjustTools[indexPath.row]
            if tool != selectedAdjustTool {
                changeAdjustTool(tool)
            }
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}

// MARK: HEInputTextViewControllerDelegate

extension HEEditImageViewController: HEInputTextViewControllerDelegate {
    func inputTextViewController(_ controller: HEInputTextViewController, stickerId: String?, didInput text: String, textColor: UIColor, fillColor: UIColor, font: UIFont, image: UIImage?) {
        if stickerId == nil { // new sticker
            self.addTextStickersView(text, textColor: textColor, fillColor: fillColor, font: font, image: image)
            return
        }
        // exist
        guard let textSticker = stickersContainer.subviews.compactMap({ $0 as? HETextStickerView}).first(where: { $0.id == stickerId }) else {
            return
        }
        guard let image = image, !text.isEmpty else {
            textSticker.moveToTrashbin()
            return
        }
        
        textSticker.startTimer()
        guard textSticker.text != text || textSticker.textColor != textColor || textSticker.fillColor != fillColor || textSticker.font != font else {
            return
        }
        textSticker.text = text
        textSticker.textColor = textColor
        textSticker.fillColor = fillColor
        textSticker.image = image
        textSticker.font = font
        let newSize = HETextStickerView.calculateSize(image: image)
        textSticker.changeSize(to: newSize)
    }
    
    func inputTextViewControllerDidCancel() {
    }
    
    
}


// MARK: 스티커 조작: HEStickerViewDelegate --

extension HEEditImageViewController: HEStickerViewDelegate {
    
    func stickerBeginOperation(_ sticker: HEBaseStickerView) {
        stickersContainer.bringSubviewToFront(sticker)
        preStickerState = sticker.state
        // 쓰레기통 표시
        trashbinView.layer.removeAllAnimations()
        trashbinView.isHidden = false
        trashbinView.alpha = 0
        var frame = trashbinView.frame
        let visibleMaxY = min(
            bottomToolViewContainer.frame.minY - 20,
            containerView.convert(imageView.frame, to: view).maxY
        )
        frame.origin.y = visibleMaxY - trashbinSize.height + 18
        let target = frame
        frame.origin.y = target.origin.y + 15
        trashbinView.frame = frame
        UIView.animate(withDuration: 0.25, delay: 0.2) {
            self.trashbinView.frame = target
            self.trashbinView.alpha = 1
        }
        // 스티커 트레이 숨김
        imageStickerTray?.hide()
        // 숨김
        setToolView(show: false)
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? HEStickerViewAdditional)?.resetState()
                (view as? HEStickerViewAdditional)?.gesIsEnabled = false
            }
        }
        
        if sticker.kind == .mosaic {
            if let stickerView = sticker as? HEImageStickerView {
                clearMosaicImageFromStickerView(stickerView)
                mosaicImageLayerMaskLayer.fillColor = UIColor.black.cgColor
                mosaicImageLayerMaskLayer.strokeColor = nil
                mosaicImageLayerMaskLayer.lineWidth = 0
                mosaicImageLayerMaskLayer.path = CGPath(ellipseIn: sticker.frame.insetBy(dx: HEImageStickerView.edgeInset, dy: HEImageStickerView.edgeInset), transform: nil)
                
                mosaicStickerActiveContainer.isHidden = false
                mosaicStickerActiveContainer.layer.addSublayer(mosaicImageLayer)
                mosaicStickerActiveContainer.layer.addSublayer(mosaicImageLayerMaskLayer)
                mosaicImageLayer.mask = mosaicImageLayerMaskLayer
            }
        }
    }
    
    func stickerOnOperation(_ sticker: HEBaseStickerView, panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: view)
        if trashbinView.frame.contains(point) {
            trashbinView.backgroundColor = .he.trashbinTintBgColor
            trashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            trashbinView.backgroundColor = .he.trashbinNormalBgColor
            trashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
        
        if sticker.kind == .mosaic { // 모자이크 영역 이동
            let inset = HEImageStickerView.edgeInset
            mosaicImageLayerMaskLayer.path = CGPath(ellipseIn: sticker.frame.insetBy(dx: inset, dy: inset), transform: nil)
        }
    }
    
    func stickerEndOperation(_ sticker: HEBaseStickerView, panGes: UIPanGestureRecognizer) {
        if selectedTool == nil {
            setToolView(show: true)
        } else {
            if selectedTool == .imageSticker {
                imageStickerTray?.show(in: view, frame: getImageStickerTrayFrame())
            }
            if !isInSubEditController {
                editingTopView.show()
            }
        }
        
        trashbinView.layer.removeAllAnimations()
        trashbinView.isHidden = true
        
        var endState: HEStickerEffect? = sticker.state
        let point = panGes.location(in: view)
        if trashbinView.frame.contains(point) {
            sticker.moveToTrashbin()
            endState = nil
        }
        
        actionManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? HEStickerViewAdditional)?.gesIsEnabled = true
        }
        
        mosaicStickerActiveContainer.isHidden = true
        if sticker.kind == .mosaic {
            if let stickerView = sticker as? HEImageStickerView {
                applyMosaicImageToStickerView(stickerView)
                mosaicImageLayerMaskLayer.path = nil
            }
        }
    }
    
    func stickerDidTap(_ sticker: HEBaseStickerView) {
        stickersContainer.bringSubviewToFront(sticker)
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? HEStickerViewAdditional)?.resetState()
            }
        }
    }
    
    func sticker(_ textSticker: HETextStickerView, editText text: String) {
        showInputTextVC(stickerId: textSticker.id, text: text, textColor: textSticker.textColor, fillColor: textSticker.fillColor, font: textSticker.font)
    }
}

// MARK: unod & redo

extension HEEditImageViewController: HEEditorManagerDelegate {
    func editorManager(_ manager: HEEditorActionManager, didUpdateActions actions: [HEEditorAction], redoActions: [HEEditorAction]) {
        self.actionListeners.forEach({ $0.didUpdatedActions(actions, redoActions: redoActions) })
    }
    
    func editorManager(_ manager: HEEditorActionManager, undoAction action: HEEditorAction) {
        switch action {
        case let .draw(path):
            undoDraw(path)
        case let .eraser(paths):
            undoEraser(paths)
        case let .clip(oldStatus, _):
            undoOrRedoClip(oldStatus)
        case let .sticker(oldState, newState):
            undoSticker(oldState, newState)
        case let .mosaic(path):
            undoMosaic(path)
        case let .filter(oldFilter, _):
            undoOrRedoFilter(oldFilter)
        case let .adjust(oldStatus, _):
            undoOrRedoAdjust(oldStatus)
        }
    }
    
    func editorManager(_ manager: HEEditorActionManager, redoAction action: HEEditorAction) {
        switch action {
        case let .draw(path):
            redoDraw(path)
        case let .eraser(paths):
            redoEraser(paths)
        case let .clip(_, newStatus):
            undoOrRedoClip(newStatus)
        case let .sticker(oldState, newState):
            redoSticker(oldState, newState)
        case let .mosaic(path):
            redoMosaic(path)
        case let .filter(_, newFilter):
            undoOrRedoFilter(newFilter)
        case let .adjust(_, newStatus):
            undoOrRedoAdjust(newStatus)
        }
    }
    
    private func undoDraw(_ path: HEDrawPath) {
        drawPaths.removeLast()
        drawLine()
    }
    
    private func redoDraw(_ path: HEDrawPath) {
        drawPaths.append(path)
        drawLine()
    }
    
    private func undoEraser(_ paths: [HEDrawPath]) {
        paths.forEach { $0.willDelete = false }
        drawPaths.append(contentsOf: paths)
        drawPaths = drawPaths.sorted { $0.index < $1.index }
        drawLine()
    }
    
    private func redoEraser(_ paths: [HEDrawPath]) {
        drawPaths.removeAll { paths.contains($0) }
        drawLine()
    }
    
    private func undoOrRedoClip(_ status: HEClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: HEMosaicPath) {
        mosaicDrawPaths.removeLast()
        generateNewMosaicImage()
    }
    
    private func redoMosaic(_ path: HEMosaicPath) {
        mosaicDrawPaths.append(path)
        generateNewMosaicImage()
    }
    
    private func undoSticker(_ oldState: HEStickerEffect?, _ newState: HEStickerEffect?) {
        guard let oldState else {
            removeSticker(id: newState?.id)
            return
        }
        
        removeSticker(id: oldState.id)
        if let sticker = HEBaseStickerView.initWithState(oldState) {
            attachSticker(sticker)
        }
    }
    
    private func redoSticker(_ oldState: HEStickerEffect?, _ newState: HEStickerEffect?) {
        guard let newState else {
            removeSticker(id: oldState?.id)
            return
        }
        
        removeSticker(id: newState.id)
        if let sticker = HEBaseStickerView.initWithState(newState) {
            attachSticker(sticker)
        }
    }
    
    private func undoOrRedoFilter(_ filter: HEFilter?) {
        guard let filter else { return }
        changeFilter(filter)
        
        let filters = HEImageEditorConfiguration.default().filters
        
        guard let filterCollectionView,
              let index = filters.firstIndex(where: { $0.name == filter.name }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        filterCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        filterCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        filterCollectionView.reloadData()
    }
    
    private func undoOrRedoAdjust(_ status: HEAdjustStatus) {
        var adjustTool: HEImageEditorConfiguration.AdjustTool?
        
        if currentAdjustStatus.brightness != status.brightness {
            adjustTool = .brightness
        } else if currentAdjustStatus.contrast != status.contrast {
            adjustTool = .contrast
        } else if currentAdjustStatus.saturation != status.saturation {
            adjustTool = .saturation
        }
        
        currentAdjustStatus = status
        preAdjustStatus = status
        adjustStatusChanged()
        
        guard let adjustTool else { return }
        
        changeAdjustTool(adjustTool)
        
        guard let adjustCollectionView,
              let index = adjustTools.firstIndex(where: { $0 == adjustTool }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        adjustCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        adjustCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        adjustCollectionView.reloadData()
    }
}
