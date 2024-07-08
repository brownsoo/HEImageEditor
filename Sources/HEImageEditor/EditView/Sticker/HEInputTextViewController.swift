//
//  HEInputTextViewController.swift
//  HEImageEditor

import UIKit
import HECommon

protocol HEInputTextViewControllerDelegate: AnyObject {
    func inputTextViewController(_ controller: HEInputTextViewController, stickerId: String?, didInput text: String, textColor: UIColor, fillColor: UIColor, font: UIFont, image: UIImage?)
    
    func inputTextViewControllerDidCancel()
}

class HEInputTextViewController: UIViewController {
    
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
        view.backgroundColor = .black
        view.alpha = 0.5
        return view
    }()
    
    private lazy var textColorBtn: UIButton = {
        let icon = UIImage.he.getImage("ic_edit_color_text") ?? UIImage(systemName: "character")
        let bt = UIButton(type: .custom)
        bt.setImage(icon?.withTintColor(.white).withRenderingMode(.alwaysOriginal), for: .normal)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .highlighted)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .selected)
        bt.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        return bt
    }()
    
    private lazy var textBackgroundBtn: UIButton = {
        let icon = UIImage.he.getImage("ic_edit_background") ?? UIImage(systemName: "rectangle.fill")
        let bt = UIButton(type: .custom)
        bt.setImage(icon?.withTintColor(.white).withRenderingMode(.alwaysOriginal), for: .normal)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .highlighted)
        bt.setImage(icon?.withTintColor(UIColor.he.rgba(71, 120, 222)), for: .selected)
        bt.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        return bt
    }()
    
    private lazy var topToolBar = HETopConfirmBarView()
    
    private lazy var textStickerMaximumLines = HEConfiguration.default().textStickerMaximumLines
    private lazy var textStickerMaximumCharactersPerLine = HEConfiguration.default().textStickerMaximumCharactersPerLine
    private lazy var textStickerCanLineBreak = HEConfiguration.default().textStickerCanLineBreak
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.keyboardAppearance = .dark
        textView.returnKeyType = textStickerCanLineBreak ? .default : .done
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.textContainer.maximumNumberOfLines = textStickerMaximumLines
        textView.textAlignment = .center
        textView.textColor = currentTextColor
        textView.text = text
        textView.font = currentFont
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.delegate = self
        ///textView.attributedText = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single]
        return textView
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
    
    private let textLayerRadius: CGFloat = 1
    
    private let maxTextCount = 50
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private var fillStyle: HEConfiguration.TextStickerFillStyle
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
            let defColor = HEConfiguration.default().textStickerDefaultTextColor
            if HEConfiguration.default().textStickerTextColors.contains(defColor) {
                currentTextColor = defColor
            } else {
                currentTextColor = HEConfiguration.default().textStickerTextColors.first ?? .white
            }
        }
        
        self.currentFillColor = fillColor ?? HEConfiguration.default().textStickerDefaultFillColor
        self.fillStyle = HEConfiguration.default().textStickerFillStyle
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
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
        topToolBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 48 + insets.top)
        
        
        textView.frame = CGRect(x: 10,
                                y: topToolBar.frame.maxY + 30,
                                width: view.frame.width - 20,
                                height: 200)
        
        toolView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: Self.toolViewHeight
        )
        colorCollView.frame = toolView.bounds
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(bgImageView)
        bgImageView.addSubview(coverView)
        
        view.addSubview(topToolBar)
        topToolBar.addCenterView(textColorBtn)
        topToolBar.addCenterView(textBackgroundBtn)
        topToolBar.cancelClickCallback = { [weak self] in self?.cancelBtnClick() }
        topToolBar.confirmClickCallback = { [weak self] in self?.doneBtnClick() }
        textColorBtn.addTarget(self, action: #selector(textColorBtnClick), for: .touchUpInside)
        textBackgroundBtn.addTarget(self, action: #selector(textBackgroundBtnClick), for: .touchUpInside)
        
        view.addSubview(textView)
        view.addSubview(toolView)
        toolView.addSubview(colorCollView)
        toolView.isHidden = true
        
        colorCollView.delegate = self
        colorCollView.dataSource = self
        
        refreshTextViewUI()
        
        
        // textView.drawDebugOutline()
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
    
    
    private func getColorSource() -> [UIColor] {
        if selectedTool == .textColor {
            return HEConfiguration.default().textStickerTextColors
        }
        return HEConfiguration.default().textStickerBackgroundColors
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
                self?.colorCollView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    @objc func cancelBtnClick() {
        dismiss(animated: true, completion: { [weak self] in
            self?.delegate?.inputTextViewControllerDidCancel()
        })
    }
    
    @objc func doneBtnClick() {
        textView.tintColor = .clear
        textView.resignFirstResponder()
        
        var image: UIImage?
        
        if !textView.text.isEmpty {
            let rects = calculateTextRectsByChar()
            let initial = CGRect(x: 10000, y: 10000, width: 0, height: 0)
            let textRect = rects.reduce(initial) { prev, rect in
                let x = min(prev.minX, rect.minX)
                let y = min(prev.minY, rect.minY)
                return CGRect(x: x,
                              y: y,
                              width: max(prev.width, rect.width),
                              height: prev.height +  rect.height)
            }
            for subview in textView.subviews {
                if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
//                    var frame = subview.frame
//                    let size = textView.sizeThatFits(frame.size)
                    image = UIGraphicsImageRenderer.he.renderImage(size: textView.bounds.size) { context in
                        if currentFillColor != .clear {
                            textLayer.render(in: context)
                        }
                        subview.layer.render(in: context)
                    }
                    // FIXME: 위 렌더러에서 한번에 처리하기..
                    image = image?.he.clipImage(angle: 0, editRect: textRect, isCircle: false)
                }
            }
        }
        
        delegate?.inputTextViewController(self, stickerId: stickerId, didInput: textView.text, textColor: currentTextColor, fillColor: currentFillColor, font: currentFont, image: image)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = (rect?.height ?? 366)
        self.keyboardHeight = keyboardH
        
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        adjustTextViewFrame(duration: max(duration, 0.25))
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        self.keyboardHeight = 0
        adjustTextViewFrame(duration: max(duration, 0.25))
    }
    
    private func adjustTextViewFrame(duration: TimeInterval) {
        let toolFrame = getToolViewFrame(keyboardHeight: self.keyboardHeight)
        let topFrame = topToolBar.frame
        let availableAea = CGSize(width: view.bounds.width, height: toolFrame.minY - topFrame.maxY)
        let size = textView.sizeThatFits(availableAea)
        let textViewFrame = CGRect(origin: CGPoint(x: max(0, (availableAea.width - size.width) / 2),
                                                   y: max(0, topFrame.maxY + (availableAea.height - size.height) / 2)),
                                   size: CGSize(width: size.width, height: size.height))
        if textView.frame == textViewFrame {
            return
        }
        if duration == 0 || abs(textView.frame.minY - textViewFrame.minY) < 5 {
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if toolView.isHidden {
            return 0
        }
        return getColorSource().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if selectedTool == .textBackground {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HETextFillColorCell.reuseIdentifier, for: indexPath) as! HETextFillColorCell
            
            let c = getColorSource()[indexPath.row]
            cell.color = c
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HETextColorCell.reuseIdentifier, for: indexPath) as! HETextColorCell
            
            let c = getColorSource()[indexPath.row]
            cell.color = c
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        
        guard !textView.text.isEmpty, currentFillColor != .clear else {
            textLayer.removeFromSuperlayer()
            return
        }
        
        let path = UIBezierPath()
        
        if fillStyle == .area {
            let textArea = textView.bounds
            
            path.move(to: CGPoint(x: textArea.minX, y: textArea.minY + textLayerRadius))
            path.addArc(withCenter: CGPoint(x: textArea.minX + textLayerRadius, y: textArea.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
            path.addLine(to: CGPoint(x: textArea.maxX - textLayerRadius, y: textArea.minY))
            path.addArc(withCenter: CGPoint(x: textArea.maxX - textLayerRadius, y: textArea.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
            
            path.addLine(to: CGPoint(x: textArea.maxX, y: textArea.maxY - textLayerRadius))
            path.addArc(withCenter: CGPoint(x: textArea.maxX - textLayerRadius, y: textArea.maxY - textLayerRadius), radius: textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            path.addLine(to: CGPoint(x: textArea.minX + textLayerRadius, y: textArea.maxY))
            path.addArc(withCenter: CGPoint(x: textArea.minX + textLayerRadius, y: textArea.maxY - textLayerRadius), radius: textLayerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            path.addLine(to: CGPoint(x: textArea.minX, y: textArea.minY + textLayerRadius))
            path.close()
            
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
    func textViewDidChange(_ textView: UITextView) {
        drawTextBackground()
        let markedTextRange = textView.markedTextRange
        guard markedTextRange == nil || (markedTextRange?.isEmpty ?? true) else {
            return
        }
        
        let text = textView.text ?? ""
        if text.count > maxTextCount {
            let endIndex = text.index(text.startIndex, offsetBy: maxTextCount)
            textView.text = String(text[..<endIndex])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !HEConfiguration.default().textStickerCanLineBreak && text == "\n" {
            doneBtnClick()
            return false
        }
        
        let composed = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let lines = composed.components(separatedBy: .newlines)
        if text == "\n" && lines.count > textStickerMaximumLines {
            return false
        }
        if let lastLineString = lines.last {
            if lastLineString.count > textStickerMaximumCharactersPerLine {
                if lines.count + 1 > textStickerMaximumLines {
                    return false
                }
                textView.text = textView.text + "\n" + text
                DispatchQueue.main.async {
                    self.drawTextBackground()
                }
                return false
            }
        }
        return true
    }
}

extension HEInputTextViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        //drawTextBackground()
    }
}

