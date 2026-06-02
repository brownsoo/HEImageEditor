//
//  HEInputTextViewController.swift
//  HEImageEditor

import UIKit
import HECommon

protocol HEInputTextViewControllerDelegate: AnyObject {
    func inputTextViewController(_ controller: HEInputTextViewController, stickerId: String?, didInput text: String, textColor: UIColor, fillColor: UIColor, font: UIFont, image: UIImage?)
    
    func inputTextViewControllerDidCancel()
}

public class HEInputTextViewController: UIViewController {
    
    weak var delegate: HEInputTextViewControllerDelegate?
    
    static let toolViewHeight: CGFloat = 44
    static let toolCellSize = CGSize(width: 40, height: 44)
    
    enum Tool {
        case textColor
        case textBackground
    }
    private var selectedTool: Tool? = nil {
        willSet {
            guard isViewLoaded else { return }
            textColorBtn.isSelected = newValue == .textColor
            textBackgroundBtn.isSelected = newValue == .textBackground
        }
    }
    private let image: UIImage?
    private var text: String
    private var currentFont: UIFont = .boldSystemFont(ofSize: HETextStickerView.fontSize)
    private var keyboardHeight: CGFloat = 0
    private var currentTextColor: UIColor {
        didSet {
            refreshTextViewUI()
        }
    }
    
    private var currentFillColor: UIColor = .clear{
        didSet {
            refreshTextViewUI()
        }
    }
    
    private lazy var bgImageView: UIImageView = {
        let view = UIImageView(image: self.image)
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var coverView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var textColorBtn: UIButton = {
        let icon = UIImage.he.getImage("icEditColorText") ?? UIImage(systemName: "character")
        let bt = UIButton(type: .custom)
        bt.setImage(icon?.withTintColor(.white).withRenderingMode(.alwaysOriginal), for: .normal)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .highlighted)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .selected)
        bt.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        return bt
    }()
    
    private lazy var textBackgroundBtn: UIButton = {
        let icon = UIImage.he.getImage("icEditBackground") ?? UIImage(systemName: "rectangle.fill")
        let bt = UIButton(type: .custom)
        bt.setImage(icon?.withTintColor(.white).withRenderingMode(.alwaysOriginal), for: .normal)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .highlighted)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .selected)
        bt.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        return bt
    }()
    
    private lazy var fillStyleBtn: UIButton = {
        let bt = UIButton(type: .custom)
        bt.setImage(fillStyleIcon(for: fillStyle), for: .normal)
        bt.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        return bt
    }()

    private lazy var topToolBar = HETopConfirmBarView()
    
    private lazy var textStickerMaximumLines = HEImageEditorConfiguration.default().textStickerMaximumLines
    private lazy var textStickerMaximumCharactersPerLine = HEImageEditorConfiguration.default().textStickerMaximumCharactersPerLine
    private lazy var textStickerCanLineBreak = HEImageEditorConfiguration.default().textStickerCanLineBreak
    
    private lazy var textView: HETextView = {
        let tv = HETextView()
        tv.keyboardAppearance = .dark
        tv.returnKeyType = textStickerCanLineBreak ? .default : .done
        tv.delegate = self
        tv.backgroundColor = .clear
        tv.textContainer.lineBreakMode = .byClipping
        tv.textAlignment = .center
        tv.textColor = currentTextColor
        tv.text = text
        tv.font = currentFont
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        tv.textContainer.lineFragmentPadding = 0
        tv.layoutManager.delegate = self
        tv.placeholder = EditorConfig.wordings.textInputPlaceholder
        
        return tv
    }()
    
    private lazy var toolView = UIView(frame: CGRect(
        x: 0,
        y: view.bounds.height - Self.toolViewHeight,
        width: view.bounds.width,
        height: Self.toolViewHeight
    ))
    
    private lazy var colorCollView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = Self.toolCellSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .black.withAlphaComponent(0.62)
        collectionView.register(HETextColorCell.self, forCellWithReuseIdentifier: HETextColorCell.reuseIdentifier)
        collectionView.register(HETextFillColorCell.self, forCellWithReuseIdentifier: HETextFillColorCell.reuseIdentifier)
        return collectionView
    }()
    
    private var shouldLayout = true
    
    private lazy var textLayer = CAShapeLayer()
    
    /// 글자 맞춤(.character) 채우기 스타일의 모서리 반경.
    private let textLayerRadius: CGFloat = 6

    /// 영역(.area) 채우기 스타일의 박스 모서리 반경.
    private let areaFillCornerRadius: CGFloat = 8
    
    private let maxTextCount = EditorConfig.maxTextLength
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private var fillStyle: HEImageEditorConfiguration.TextStickerFillStyle
    private let stickerId: String?
    
    init(stickerId: String? = nil,
         image: UIImage?, 
         text: String? = nil,
         font: UIFont? = nil, 
         textColor: UIColor? = nil,
         fillColor: UIColor? = nil) {
        self.stickerId = stickerId
        self.image = image
        self.text = text ?? ""
        if let font = font {
            self.currentFont = font.withSize(HETextStickerView.fontSize)
        }
        if let textColor = textColor {
            currentTextColor = textColor
        } else {
            let defColor = HEImageEditorConfiguration.default().textStickerDefaultTextColor
            if HEImageEditorConfiguration.default().textStickerTextColors.contains(defColor) {
                currentTextColor = defColor
            } else {
                currentTextColor = HEImageEditorConfiguration.default().textStickerTextColors.first ?? .white
            }
        }
        
        self.currentFillColor = fillColor ?? HEImageEditorConfiguration.default().textStickerDefaultFillColor
        self.fillStyle = HEImageEditorConfiguration.default().textStickerFillStyle
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        addKeyboardObserver()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textView.becomeFirstResponder()
        UIView.animate(withDuration: 0.18) {
            self.topToolBar.alpha = 1
            self.coverView.alpha = 1
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shouldLayout else { return }
        
        shouldLayout = false
        bgImageView.frame = view.bounds
        
        if deviceIsiPad() {
            if UIApplication.shared.he.findWindowScenes().first?.interfaceOrientation.isLandscape == true {
                bgImageView.contentMode = .scaleAspectFill
            } else {
                bgImageView.contentMode = .scaleAspectFit
            }
        }
        
        coverView.frame = bgImageView.bounds
        
        let insets = view.safeAreaInsets
        topToolBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: HETopConfirmBarView.contentHeight + insets.top)
        
        toolView.frame = CGRect(
            x: 0,
            y: view.bounds.height,
            width: view.bounds.width,
            height: Self.toolViewHeight
        )
        colorCollView.frame = toolView.bounds
        
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    private func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(bgImageView)
        bgImageView.addSubview(coverView)
        coverView.alpha = 0
        
        view.addSubview(topToolBar)
        topToolBar.addCenterView(textColorBtn)
        topToolBar.addCenterView(textBackgroundBtn)
        topToolBar.addCenterView(fillStyleBtn)
        topToolBar.cancelClickCallback = { [weak self] in self?.cancelBtnClick() }
        topToolBar.confirmClickCallback = { [weak self] in self?.doneBtnClick() }
        topToolBar.alpha = 0
        topToolBar.backgroundColor = .black

        textColorBtn.addTarget(self, action: #selector(textColorBtnClick), for: .touchUpInside)
        textBackgroundBtn.addTarget(self, action: #selector(textBackgroundBtnClick), for: .touchUpInside)
        fillStyleBtn.addTarget(self, action: #selector(fillStyleBtnClick), for: .touchUpInside)
        
        view.addSubview(textView)
        view.addSubview(toolView)
        toolView.addSubview(colorCollView)
        toolView.isHidden = true
        
        colorCollView.delegate = self
        colorCollView.dataSource = self
        
        refreshTextViewUI()
    }
    
    private func refreshTextViewUI() {
        guard isViewLoaded else { return }
        textView.textColor = currentTextColor
        drawTextBackground()
    }
    
   
    @objc private func textColorBtnClick() {
        if selectedTool == .textColor {
            selectedTool = nil
            hideToolsView()
            return
        }
        selectedTool = .textColor
        showToolsView()
    }
    
    @objc private func textBackgroundBtnClick() {
        if selectedTool == .textBackground {
            selectedTool = nil
            hideToolsView()
            return
        }
        selectedTool = .textBackground
        showToolsView()
    }

    @objc private func fillStyleBtnClick() {
        fillStyle = (fillStyle == .area) ? .character : .area
        fillStyleBtn.setImage(fillStyleIcon(for: fillStyle), for: .normal)
        // 배경 채우기 모양이 바뀌므로 미리보기를 다시 그린다.
        drawTextBackground()
    }

    /// 현재 채우기 스타일을 나타내는 아이콘.
    private func fillStyleIcon(for style: HEImageEditorConfiguration.TextStickerFillStyle) -> UIImage? {
        let name = (style == .area) ? "character.textbox" : "a.square.fill"
        return UIImage(systemName: name)?
            .withTintColor(.white)
            .withRenderingMode(.alwaysOriginal)
    }

    
    private func getColorSource() -> [UIColor] {
        if selectedTool == .textColor {
            return HEImageEditorConfiguration.default().textStickerTextColors
        }
        return HEImageEditorConfiguration.default().textStickerBackgroundColors
    }
    
    private func updateCollContentInset() {
        let toolsCount = CGFloat(getColorSource().count)
        let minimumWidth = toolsCount * Self.toolCellSize.width
        let fullSpace = self.view.frame.width
        var inset: CGFloat = 0
        if minimumWidth < fullSpace {
            let remain = fullSpace - minimumWidth
            inset = remain / 2
        }
        self.colorCollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    private func hideToolsView() {
        toolView.isHidden = true
    }
    
    private func showToolsView() {
        updateCollContentInset()
        colorCollView.reloadData()
        toolView.frame = getToolViewFrame(keyboardHeight: self.keyboardHeight)
        toolView.isHidden = false
        
        var index: Int?
        if selectedTool == .textColor {
            index = getColorSource().firstIndex(where: { $0 == currentTextColor })
        } else if selectedTool == .textBackground {
            index = getColorSource().firstIndex(where: { $0 == currentFillColor })
        }
        
        if let index {
            DispatchQueue.main.async { [weak self] in
                self?.colorCollView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    private func animateDismiss(delay: TimeInterval = 0, complete: @escaping () -> Void) {

        UIView.animate(withDuration: 0.18, animations: { self.coverView.alpha = 0})

        if textView.isFirstResponder {
            textView.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20 + delay) {
                complete()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                complete()
            }
        }
    }
    
    @objc func cancelBtnClick() {
        animateDismiss {  [weak self] in
            self?.dismiss(animated: false, completion: {
                self?.delegate?.inputTextViewControllerDidCancel()
            })
        }
    }
    
    @objc func doneBtnClick() {
        
        if textView.text.isEmpty {
            return
        }
        
        textView.tintColor = .clear
        textView.resignFirstResponder()
        
        var image: UIImage?
        // 채우기 스타일에 따라 잘라낼 영역(textRect)만 달라지고,
        // 렌더링은 두 스타일 모두 동일하게 처리한다.
        let textRect: CGRect
        if fillStyle == .area {
            // 영역 채우기: 텍스트 박스 전체를 사용한다.
            textRect = textView.bounds
        } else {
            // 글자 맞춤: 글자별 사각형들의 합집합을 사용한다.
            let rects = calculateTextRectsByChar()
            let initial = CGRect(x: 10000, y: 10000, width: 0, height: 0)
            textRect = rects.reduce(initial) { prev, rect in
                let x = min(prev.minX, rect.minX)
                let y = min(prev.minY, rect.minY)
                return CGRect(x: x,
                              y: y,
                              width: max(prev.width, rect.width),
                              height: prev.height +  rect.height)
            }
        }

        for subview in textView.subviews {
            if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
                image = UIGraphicsImageRenderer.he.renderImage(size: textView.bounds.size) { context in
                    if currentFillColor != .clear {
                        textLayer.render(in: context)
                    }
                    subview.layer.render(in: context)
                }
                image = image?.he.clipImage(angle: 0, editRect: textRect, isCircle: false)
            }
        }
        
        animateDismiss(delay: 0.18) {  [weak self] in
            self?.dismiss(animated: false) {
                guard let self else { return }
                self.delegate?.inputTextViewController(self, stickerId: self.stickerId, didInput: self.textView.text, textColor: self.currentTextColor, fillColor: self.currentFillColor, font: self.currentFont, image: image)
                
            }
        }
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = (rect?.height ?? 366)
        self.keyboardHeight = keyboardH
        
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        adjustTextViewFrame(duration: max(duration, 0.18))
        
        if selectedTool == nil {
            selectedTool = .textColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.showToolsView()
        }
        
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        self.keyboardHeight = 0
        adjustTextViewFrame(duration: max(duration, 0.18))
        selectedTool = nil
        hideToolsView()
    }
    
    private func adjustTextViewFrame(duration: TimeInterval) {
        let toolFrame = getToolViewFrame(keyboardHeight: self.keyboardHeight)
        let topFrame = topToolBar.frame
        let maxWidth = view.bounds.width
        let availableAea = CGSize(width: maxWidth,
                                  height: toolFrame.minY - topFrame.maxY)
        
        let placeholderFrame = textView.placeholderFrame()
        // trace(placeholderFrame)
        let size: CGSize
        if textView.text.isEmpty {
            size = placeholderFrame.size
        } else {
            size = textView.sizeThatFits(availableAea)
        }
        
        let textViewFrame = CGRect(origin: CGPoint(x: max(0, (view.bounds.width - size.width) / 2),
                                                   y: max(0, topFrame.maxY + (availableAea.height - size.height) / 2)),
                                   size: CGSize(width: size.width, 
                                                height: size.height))
        if textView.frame == textViewFrame {
            return
        }
        
        if duration == 0 {
            self.toolView.frame = toolFrame
            self.textView.frame = textViewFrame
        } else {
            UIView.animate(withDuration: max(duration, 0.25)) {
                self.toolView.frame = toolFrame
                self.textView.frame = textViewFrame
            }
        }
    }
    
    private func getToolViewFrame(keyboardHeight: CGFloat) -> CGRect {
        return CGRect(
            x: 0,
            y: view.bounds.height - keyboardHeight - Self.toolViewHeight,
            width: view.bounds.width,
            height: Self.toolViewHeight
        )
    }
}

extension HEInputTextViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if toolView.isHidden {
            return 0
        }
        return getColorSource().count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if selectedTool == .textBackground {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HETextFillColorCell.reuseIdentifier, for: indexPath) as! HETextFillColorCell
            
            let c = getColorSource()[indexPath.row]
            cell.color = c
            cell.isSelected = c == currentFillColor
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HETextColorCell.reuseIdentifier, for: indexPath) as! HETextColorCell
            
            let c = getColorSource()[indexPath.row]
            cell.color = c
            cell.isSelected = c == currentTextColor
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? HETextFillColorCell {
            cell.isSelected = cell.color == currentFillColor
        } else if let cell = cell as? HETextColorCell {
            cell.isSelected = cell.color == currentTextColor
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = getColorSource()[indexPath.row]
        if selectedTool == .textColor {
            currentTextColor = color
        } else if selectedTool == .textBackground {
            currentFillColor = color
        } else {
            return
        }
    }
}

// MARK: Draw text layer

extension HEInputTextViewController {
    private func drawTextBackground() {
        
        adjustTextViewFrame(duration: 0)
        
        let inputText = textView.text ?? ""
        guard !inputText.isEmpty else {
            textView.placeholderLabel?.backgroundColor = currentFillColor
            return
        }
        
        guard currentFillColor != .clear else {
            textLayer.removeFromSuperlayer()
            return
        }
        
        let path = UIBezierPath()
        
        if fillStyle == .area {
            let textArea = textView.bounds
            path.append(UIBezierPath(roundedRect: textArea, cornerRadius: areaFillCornerRadius))
        } else {
            // 텍스트 글자에 맞춰 배경 생성
            let rects = calculateTextRectsByChar()
            for (index, rect) in rects.enumerated() {
                if index == 0 {
                    path.move(to: CGPoint(x: rect.minX, y: rect.minY + textLayerRadius))
                    path.addArc(withCenter: CGPoint(x: rect.minX + textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
                    path.addLine(to: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                } else {
                    let preRect = rects[index - 1]
                    if rect.maxX > preRect.maxX {
                        path.addLine(to: CGPoint(x: preRect.maxX, y: rect.minY - textLayerRadius))
                        path.addArc(withCenter: CGPoint(x: preRect.maxX + textLayerRadius, y: rect.minY - textLayerRadius), radius: textLayerRadius, startAngle: -.pi, endAngle: -.pi * 1.5, clockwise: false)
                        path.addLine(to: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY))
                        path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                    } else if rect.maxX < preRect.maxX {
                        path.addLine(to: CGPoint(x: preRect.maxX, y: preRect.maxY - textLayerRadius))
                        path.addArc(withCenter: CGPoint(x: preRect.maxX - textLayerRadius, y: preRect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                        path.addLine(to: CGPoint(x: rect.maxX + textLayerRadius, y: preRect.maxY))
                        path.addArc(withCenter: CGPoint(x: rect.maxX + textLayerRadius, y: preRect.maxY + textLayerRadius), radius: textLayerRadius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
                    } else {
                        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + textLayerRadius))
                    }
                }
                
                if index == rects.count - 1 {
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - textLayerRadius))
                    path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                    path.addLine(to: CGPoint(x: rect.minX + textLayerRadius, y: rect.maxY))
                    path.addArc(withCenter: CGPoint(x: rect.minX + textLayerRadius, y: rect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                    
                    let firstRect = rects[0]
                    path.addLine(to: CGPoint(x: firstRect.minX, y: firstRect.minY + textLayerRadius))
                    path.close()
                }
            }
        }
        
        textLayer.path = path.cgPath
        textLayer.fillColor = currentFillColor.cgColor
        if textLayer.superlayer == nil {
            textView.layer.insertSublayer(textLayer, at: 0)
        }
    }
    
    private func calculateTextRectsByChar() -> [CGRect] {
        let layoutManager = textView.layoutManager
        
        let range = layoutManager.glyphRange(forCharacterRange: NSMakeRange(0, textView.text.utf16.count), actualCharacterRange: nil)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        var rects: [CGRect] = []
        
        let insetLeft = textView.textContainerInset.left
        let insetTop = textView.textContainerInset.top
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, range, _ in
            rects.append(CGRect(x: usedRect.minX - 10 + insetLeft,
                                y: usedRect.minY - 8 + insetTop,
                                width: usedRect.width + 20,
                                height: usedRect.height + 16))
        }
        
        guard rects.count > 1 else {
            return rects
        }
        
        for i in 1..<rects.count {
            processRects(&rects, index: i, maxIndex: i)
        }
        
        return rects
    }
    
    private func processRects(_ rects: inout [CGRect], index: Int, maxIndex: Int) {
        guard rects.count > 1, index > 0, index <= maxIndex else {
            return
        }
        
        var preRect = rects[index - 1]
        var currRect = rects[index]
        
        var preChanged = false
        var currChanged = false
        
        // 현재 직사각형 너비는 위의 직사각형 너비보다 크지만 차이는 preRect의 2배 미만입니다.
        if currRect.width > preRect.width, currRect.width - preRect.width < 2 * textLayerRadius {
            var size = preRect.size
            size.width = currRect.width
            preRect = CGRect(origin: preRect.origin, size: size)
            preChanged = true
        }
        
        if currRect.width < preRect.width, preRect.width - currRect.width < 2 * textLayerRadius {
            var size = currRect.size
            size.width = preRect.width
            currRect = CGRect(origin: currRect.origin, size: size)
            currChanged = true
        }
        
        if preChanged {
            rects[index - 1] = preRect
            processRects(&rects, index: index - 1, maxIndex: maxIndex)
        }
        
        if currChanged {
            rects[index] = currRect
            processRects(&rects, index: index + 1, maxIndex: maxIndex)
        }
    }
}


extension HEInputTextViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.drawTextBackground()
        
        let markedTextRange = textView.markedTextRange
        guard markedTextRange == nil || (markedTextRange?.isEmpty ?? true) else {
            return
        }
        let text = textView.text ?? ""
        var resolved = text
        let concreateText = text.filter({ !$0.isNewline })
        // trace(concreateText)
        if concreateText.count > maxTextCount { // 총 길이 제한
            let offset = -(concreateText.count - maxTextCount)
            let endIndex = text.index(text.endIndex, offsetBy: offset)
            resolved = String(text[..<endIndex])
        }
        
        var makingLines: [String] = []
        var selectedRange = textView.selectedRange
        
        var lines = resolved.components(separatedBy: .newlines)
        var cursor = 0
        var lineIndex = 0
        
        while lineIndex < lines.count {
            let line = lines[lineIndex]
            if line.count > textStickerMaximumCharactersPerLine {
                var start = line.startIndex
                var offset = 0
                while start < line.endIndex {
                    offset = min(offset + textStickerMaximumCharactersPerLine, line.count - offset)
                    let end = line.index(start, offsetBy: offset)
                    let comp = line[start..<end]
                    makingLines.append(String(comp))
                    
                    cursor += offset
                    
                    //lg.trace("\(offset)  cursor - \(cursor) location - \(selectedRange.location)  :: \(comp)")
                    
                    if selectedRange.location > cursor { // 줄바꿈에 따른 커서 이동
                        selectedRange.location += 1
                    }
                    
                    start = end
                }
                if lineIndex + 1 < lines.count { // 다음 글줄에 붙여서 계산하도록 한다.
                    let lastFriction = makingLines.popLast() ?? ""
                    lines[lineIndex + 1] = lastFriction + lines[lineIndex + 1]
                }
            } else {
                cursor += line.count
                makingLines.append(line)
                //lg.trace("cursor - \(cursor)")
            }
            
            lineIndex += 1
        }
        
        var newlines: [String] = makingLines
        if newlines.count > textStickerMaximumLines {
            lg.trace("넘어서는 라인 제거")
            newlines = Array(newlines[0..<textStickerMaximumLines])
        }
        
        resolved = newlines.joined(separator: "\n")
        
        if text != resolved {
            var newRange = NSRange()
            newRange.location = min(selectedRange.location, resolved.count)
            newRange.length = min(selectedRange.length, resolved.count - newRange.location)
            
            textView.text = resolved
            // trace(newRange)
            textView.selectedRange = newRange
            self.drawTextBackground()
        }
        
        
        DispatchQueue.main.async {
            self.topToolBar.confirmButton.isEnabled = !concreateText.filter{ !$0.isWhitespace }.isEmpty
        }
        
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !HEImageEditorConfiguration.default().textStickerCanLineBreak && text == "\n" {
            doneBtnClick()
            return false
        }
        
        if text == "\n" {
            let exist = (textView.text as NSString)
            let lines = exist.components(separatedBy: .newlines)
            if lines.count + 1 > textStickerMaximumLines {
                return false
            }
        }
        
        return true
    }
}

extension HEInputTextViewController: NSLayoutManagerDelegate {
    public func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        //drawTextBackground()
    }
}

