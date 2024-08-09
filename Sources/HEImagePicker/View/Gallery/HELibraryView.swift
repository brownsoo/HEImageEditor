//
//  HELibraryView.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit
import Photos
import HECommon

/// HELibraryViewController 의 뷰
final class HELibraryView: UIView {

    // MARK: - Public vars

    internal let previewBoxMinimalVisibleHeight: CGFloat  = 104
    internal var previewBoxConstraintTop: NSLayoutConstraint?
    /// 앨범 내 이미지 콜렉션 
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
    
    internal let albumEmptyView: UIView = {
        let v = EdgeLineView()
        v.backgroundColor = .white
        v.edges = .top
        let label = UILabel()
        label.text = PickerConfig.wordings.photoEmptyMessage
        label.textColor = UIColor(white: 187 / 255.0, alpha: 1.0)
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textAlignment = .center
        v.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
        return v
    }()
    
    /// 상단 미리보기
    internal lazy var previewBox: HEPreviewBoxView = {
        let v = HEPreviewBoxView()
        v.accessibilityIdentifier = "previewViewBox"
        return v
    }()
    
    internal var currentZoomableView: HEAssetZoomableView? {
        return previewBox.currentZoomableView
    }

    internal let albumNameBt: UIButton = {
        let bt = UIButton()
        if PickerConfig.library.mediaType == .video {
            bt.setTitle(PickerConfig.wordings.allVideos, for: .normal)
        } else {
            bt.setTitle(PickerConfig.wordings.allPhotos, for: .normal)            
        }
        bt.setTitleColor(.init(white: 52/255.0, alpha: 1), for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        bt.semanticContentAttribute = .forceRightToLeft
        bt.setImage(PickerConfig.icons.arrowDownIcon?.he.resize(CGSize(width: 16, height: 16))?.withTintColor(UIColor(white: 51 / 255.0, alpha: 1.0), renderingMode: .alwaysOriginal), for: .normal)
        bt.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        bt.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 18)
        return bt
    }()
    
    internal lazy var libraryBeingUpdateToast: UIView = {
        let uv = UIView()
        uv.backgroundColor = .black.withAlphaComponent(0.5)
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12)
        lb.textColor = .white
        lb.textAlignment = .center
        lb.text = PickerConfig.wordings.libraryBeingChange
        uv.addSubview(lb)
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.leadingAnchorConstraintToSuperview(8)
        lb.trailingAnchorConstraintToSuperview(-8)
        lb.topAnchorConstraintToSuperview(4)
        lb.bottomAnchorConstraintToSuperview(-4)
        return uv
    }()
    
    internal var cameraPhotoButton: UIButton?
    internal let countView = UIView()
    internal let countButton: UIButton = {
        let bt = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
        bt.setTitle("0", for: .normal)
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        bt.titleLabel?.textAlignment = .center
        bt.setTitleColor(.white, for: .normal)
        bt.backgroundColor = UIColor(r: 71, g: 120, b: 222, a: 1)
        bt.layer.cornerRadius = 16
        bt.layer.masksToBounds = true
        return bt
    }()

    
    // MARK: - Private vars

    private let albumHeadlineView: UIView = {
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
    
    func setSelectedCount(_ count: Int) {
        countButton.setTitle(String(count), for: .normal)
        countView.isHidden = count == 0 || !isMultipleSelectionEnabled
    }

    // MARK: Loader and progress
    

    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }

    // MARK: Crop Rect

    func currentCropRect() -> CGRect {
        if !PickerConfig.library.usingClop // no clop
            || previewBox.collView?.collectionViewLayout is CenteredCellFlowLayout
        {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        guard let cropView = currentZoomableView else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }

    // MARK: Curtain

    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(previewBoxConstraintTop?.constant ?? 0)
        / (previewBox.frame.height - previewBoxMinimalVisibleHeight)
        previewBox.curtain.alpha = imageCurtainAlpha
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
        previewBox.setMultipleSelectionMode(on: on)
    }
    
    func showLibraryBeingChangeMessage() {
        addSubview(libraryBeingUpdateToast)
        libraryBeingUpdateToast.translatesAutoresizingMaskIntoConstraints = false
        libraryBeingUpdateToast.edgesConstraintToSuperview(edges: [.top, .horizontal])
    }
    
    func hideLibraryBeingChangeMessage() {
        libraryBeingUpdateToast.removeFromSuperview()
    }
    
    // MARK: - Private Methods

    private func setupLayout() {
        
        addSubview(collectionContainerView)
        collectionContainerView.addSubview(albumCollectionView)
        collectionContainerView.addSubview(albumHeadlineView)
        collectionContainerView.addSubview(albumEmptyView)
        addSubview(previewBox)
        addSubview(progressView)
        
        
        collectionContainerView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: [.horizontal, .bottom])
            v.topAnchorConstraintTo(self.safeAreaLayoutGuide.topAnchor)
        }
        albumCollectionView.makeConstraints { v in
            v.topAnchorConstraintTo(albumHeadlineView.bottomAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintToSuperview()
        }
        
        albumEmptyView.isHidden = true
        albumEmptyView.makeConstraints { v in
            v.topAnchorConstraintTo(albumHeadlineView.bottomAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintToSuperview()
            v.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
            v.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        }

        var topConstraint: NSLayoutConstraint?
        previewBox.makeConstraints { v in
            topConstraint = v.topAnchorConstraintToSuperview()
            v.bottomAnchorConstraintTo(albumHeadlineView.topAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
        }
        albumHeadlineView.makeConstraints { v in
            v.heightAnchorConstraintTo(56)
            v.edgesConstraintToSuperview(edges: .horizontal)
        }

        self.previewBoxConstraintTop = topConstraint

        progressView.makeConstraints { v in
            v.heightAnchorConstraintTo(5)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintTo(albumHeadlineView.topAnchor)
        }
        
        albumHeadlineView.addSubview(albumNameBt)
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
        albumHeadlineView.addSubview(rearStack)
        rearStack.makeConstraints { v in
            v.trailingAnchorConstraintToSuperview(-7)
            v.topAnchorConstraintToSuperview()
            v.bottomAnchorConstraintToSuperview()
        }
        
        // 카운트 추가
        countView.addSubview(countButton)
        rearStack.addArrangedSubview(countView)
        countView.makeConstraints { v in
            v.sizeAnchorConstraintTo(42)
            v.isHidden = !(PickerConfig.library.defaultMultipleSelection || isMultipleSelectionEnabled)
        }
        countButton.makeConstraints { bt in
            bt.sizeAnchorConstraintTo(32)
            bt.centerXAnchorConstraintToSuperview()
            bt.centerYAnchorConstraintToSuperview()
        }
        
        // 카메라 사용 여부에 따라 버튼 추가
        if PickerConfig.pickerSources.contains(.photoCapture)
            || PickerConfig.pickerSources.contains(.videoCapture) {
            let iconView = UIImageView(frame: .init(origin: .zero, size: CGSize(width: 32, height: 32)))
            iconView.contentMode = .center
            iconView.backgroundColor = UIColor(white: 136 / 255.0, alpha: 1.0)
            iconView.layer.cornerRadius = 16
            iconView.layer.masksToBounds = true
            iconView.image = PickerConfig.icons.cameraFillIcon?.he.resize(CGSize(width: 16, height: 16))
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
