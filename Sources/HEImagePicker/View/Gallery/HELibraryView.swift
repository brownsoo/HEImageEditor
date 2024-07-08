//
//  HELibraryView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import Photos

/// 메인 뷰
final class HELibraryView: UIView {

    // MARK: - Public vars

    internal let previewBoxMinimalVisibleHeight: CGFloat  = 104
    internal var previewBoxConstraintTop: NSLayoutConstraint?
    /// 앨범 이미지 콜렉션 
    internal let albumCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.backgroundColor = PickerConfig.colors.libraryScreenBackgroundColor
        v.collectionViewLayout = layout
        v.showsHorizontalScrollIndicator = false
        v.alwaysBounceVertical = true
        return v
    }()
    /// 상단 미리보기 
    // TODO: 이미지 리스트로 변경
    internal lazy var preivewBox: HEAssetViewBox = {
        let v = HEAssetViewBox(frame: .zero, zoomableView: HEAssetZoomableView(frame: .zero))
        v.accessibilityIdentifier = "assetViewContainer"
        return v
    }()
    // TODO: 변경하기 - 확대는... 편집 모드가 아닌 경우에 처리.
    internal var assetZoomableView: HEAssetZoomableView {
        return preivewBox.zoomableView
    }

    internal let albumNameBt: UIButton = {
        let bt = UIButton()
        bt.setTitle(PickerConfig.wordings.allPhotos, for: .normal)
        bt.setTitleColor(.init(white: 52/255.0, alpha: 1), for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        bt.semanticContentAttribute = .forceRightToLeft
        bt.setImage(PickerConfig.icons.arrowDownIcon?.resized(to: CGSize(width: 16, height: 16))?.withTintColor(UIColor(white: 51 / 255.0, alpha: 1.0), renderingMode: .alwaysOriginal), for: .normal)
        bt.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        bt.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 18)
        return bt
    }()
    
    internal var cameraPhotoButton: UIButton?
    internal var cameraVideoButton: UIButton?
    internal var countView: UIView?
    internal var countLabel: UILabel?
    
    // MARK: - Private vars

    private let line: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()
    
    private var isMultipleSelectionEnabled = false
    
    /// When video is processing this bar appears
    private let progressView: UIProgressView = {
        let v = UIProgressView()
        v.progressViewStyle = .bar
        v.trackTintColor = PickerConfig.colors.progressBarTrackColor
        v.progressTintColor = PickerConfig.colors.progressBarCompletedColor ?? PickerConfig.colors.tintColor
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }()
    private let collectionContainerView: UIView = {
        let v = UIView()
        v.accessibilityIdentifier = "collectionContainerView"
        return v
    }()
    
    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.preivewBox.squareCropButton?.isEnabled = !self.shouldShowLoader
                self.preivewBox.spinnerIsShown = self.shouldShowLoader
            }
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Public Methods

    // MARK: Loader and progress
    
    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                if self.shouldShowLoader == true {
                    UIView.animate(withDuration: 0.2) {
                        self.preivewBox.spinnerView.alpha = 1
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: 0.2) {
                self.preivewBox.spinnerView.alpha = 1
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        preivewBox.spinnerView.alpha = 0
    }

    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }

    // MARK: Crop Rect

    func currentCropRect() -> CGRect {
        let cropView = assetZoomableView
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }

    // MARK: Curtain

    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(previewBoxConstraintTop?.constant ?? 0)
        / (preivewBox.frame.height - previewBoxMinimalVisibleHeight)
        preivewBox.curtain.alpha = imageCurtainAlpha
    }

    func cellSize() -> CGSize {
        var screenWidth: CGFloat = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad && HEImagePickerConfiguration.widthOniPad > 0 {
            screenWidth =  HEImagePickerConfiguration.widthOniPad
        }
        let size = screenWidth / 4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }

    func setMultipleSelectionMode(on: Bool) {
        isMultipleSelectionEnabled = on
        preivewBox.setMultipleSelectionMode(on: on)
        countLabel?.isHidden = !on
    }
    
    // MARK: - Private Methods

    private func setupLayout() {
        
        addSubview(collectionContainerView)
        collectionContainerView.addSubview(albumCollectionView)
        collectionContainerView.addSubview(line)
        addSubview(preivewBox)
        addSubview(progressView)
        
        preivewBox.backgroundColor = .green
        // assetViewBox.backgroundColor = PickerConfig.colors.assetViewBackgroundColor
        
        collectionContainerView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: [.horizontal, .bottom])
            v.topAnchorConstraintTo(self.safeAreaLayoutGuide.topAnchor)
        }
        albumCollectionView.makeConstraints { v in
            v.topAnchorConstraintTo(line.bottomAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintToSuperview()
        }

        var topConstraint: NSLayoutConstraint?
        preivewBox.makeConstraints { v in
            topConstraint = v.topAnchorConstraintToSuperview()
            v.bottomAnchorConstraintTo(line.topAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
        }
        line.makeConstraints { v in
            v.heightAnchorConstraintTo(56)
            v.edgesConstraintToSuperview(edges: .horizontal)
        }

        self.previewBoxConstraintTop = topConstraint

        progressView.makeConstraints { v in
            v.heightAnchorConstraintTo(5)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintTo(line.topAnchor)
        }
        
        line.addSubview(albumNameBt)
        albumNameBt.makeConstraints { v in
            v.leadingAnchorConstraintToSuperview()
            v.centerYAnchorConstraintToSuperview()
        }
        
        let rearStack = UIStackView()
        rearStack.axis = .horizontal
        rearStack.alignment = .center
        rearStack.spacing = 0
        rearStack.setContentHuggingPriority(.required, for: .horizontal)
        rearStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        line.addSubview(rearStack)
        rearStack.makeConstraints { v in
            v.trailingAnchorConstraintToSuperview(-7)
            v.topAnchorConstraintToSuperview()
            v.bottomAnchorConstraintToSuperview()
        }
        
        
        // 카운트 추가
        let lb = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
        lb.adjustsFontSizeToFitWidth = true
        lb.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        lb.backgroundColor = UIColor(r: 71, g: 120, b: 222, a: 1)
        lb.text = "0"
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.widthAnchor.constraint(equalToConstant: 32).isActive = true
        lb.heightAnchor.constraint(equalToConstant: 32).isActive = true
        lb.layer.cornerRadius = 16
        lb.layer.masksToBounds = true
        lb.textAlignment = .center
        countLabel = lb
        let lbWrap = UIView()
        lbWrap.translatesAutoresizingMaskIntoConstraints = false
        lbWrap.widthAnchor.constraint(equalToConstant: 42).isActive = true
        lbWrap.heightAnchor.constraint(equalToConstant: 42).isActive = true
        lbWrap.isHidden = !(PickerConfig.library.defaultMultipleSelection || isMultipleSelectionEnabled)
        lbWrap.addSubview(lb)
        lb.centerXAnchorConstraintToSuperview()
        lb.centerYAnchorConstraintToSuperview()
        rearStack.addArrangedSubview(lbWrap)
        countView = lbWrap
        
        // 카메라 사용 여부에 따라 버튼 추가
        if PickerConfig.pickerSources.contains(.photoCapture) || PickerConfig.pickerSources.contains(.videoCapture) {
            if PickerConfig.pickerSources.contains(.videoCapture) {
                let iconImage = PickerConfig.icons.videoFillIcon?.withTintColor(.white, renderingMode: .alwaysOriginal)
                let iconView = UIImageView(frame: .init(origin: .zero, size: CGSize(width: 32, height: 32)))
                iconView.contentMode = .center
                iconView.backgroundColor = UIColor(white: 136 / 255.0, alpha: 1.0)
                iconView.layer.cornerRadius = 16
                iconView.layer.masksToBounds = true
                iconView.image = iconImage
                let renderer = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: CGSize(width: 32, height: 32)))
                let icon = renderer.image { rendererContext in
                    iconView.layer.render(in: rendererContext.cgContext)
                }
                
                let bt = UIButton(frame: .init(origin: .zero, size: CGSize(width: 42, height: 42)))
                bt.contentEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
                bt.setImage(icon, for: .normal)
                rearStack.addArrangedSubview(bt)
                cameraVideoButton = bt
            }
            
            if PickerConfig.pickerSources.contains(.photoCapture) {
                let iconView = UIImageView(frame: .init(origin: .zero, size: CGSize(width: 32, height: 32)))
                iconView.contentMode = .center
                iconView.backgroundColor = UIColor(white: 136 / 255.0, alpha: 1.0)
                iconView.layer.cornerRadius = 16
                iconView.layer.masksToBounds = true
                iconView.image = PickerConfig.icons.cameraFillIcon?.resized(to: CGSize(width: 16, height: 16))
                let renderer = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: CGSize(width: 32, height: 32)))
                let icon = renderer.image { rendererContext in
                    iconView.layer.render(in: rendererContext.cgContext)
                }
                
                let bt = UIButton(frame: .init(origin: .zero, size: CGSize(width: 42, height: 42)))
                bt.contentEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
                bt.setImage(icon, for: .normal)
                rearStack.addArrangedSubview(bt)
                cameraPhotoButton = bt
            }
            
        }
        
    }
}
