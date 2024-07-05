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

    internal let assetZoomableViewMinimalVisibleHeight: CGFloat  = 104
    internal var assetViewContainerConstraintTop: NSLayoutConstraint?
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
    internal lazy var assetViewBox: HEAssetViewBox = {
        let v = HEAssetViewBox(frame: .zero, zoomableView: HEAssetZoomableView(frame: .zero))
        v.accessibilityIdentifier = "assetViewContainer"
        return v
    }()
    // TODO: 변경하기 - 확대는... 편집 모드가 아닌 경우에 처리.
    internal var assetZoomableView: HEAssetZoomableView {
        return assetViewBox.zoomableView
    }

    // MARK: - Private vars

    private let line: UIView = {
        let v = UIView()
        v.backgroundColor = .blue
        return v
    }()
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
                self.assetViewBox.squareCropButton.isEnabled = !self.shouldShowLoader
                self.assetViewBox.spinnerIsShown = self.shouldShowLoader
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
                        self.assetViewBox.spinnerView.alpha = 1
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: 0.2) {
                self.assetViewBox.spinnerView.alpha = 1
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        assetViewBox.spinnerView.alpha = 0
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
        let imageCurtainAlpha = abs(assetViewContainerConstraintTop?.constant ?? 0)
        / (assetViewBox.frame.height - assetZoomableViewMinimalVisibleHeight)
        assetViewBox.curtain.alpha = imageCurtainAlpha
    }

    func cellSize() -> CGSize {
        var screenWidth: CGFloat = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad && HEImagePickerConfiguration.widthOniPad > 0 {
            screenWidth =  HEImagePickerConfiguration.widthOniPad
        }
        let size = screenWidth / 4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }

    // MARK: - Private Methods

    private func setupLayout() {
        
        addSubview(collectionContainerView)
        collectionContainerView.addSubview(albumCollectionView)
        collectionContainerView.addSubview(line)
        addSubview(assetViewBox)
        addSubview(progressView)
        
        assetViewBox.backgroundColor = .green
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
        assetViewBox.makeConstraints { v in
            topConstraint = v.topAnchorConstraintToSuperview()
            v.bottomAnchorConstraintTo(line.topAnchor)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
        }
        line.makeConstraints { v in
            v.heightAnchorConstraintTo(56)
            v.edgesConstraintToSuperview(edges: .horizontal)
        }

        self.assetViewContainerConstraintTop = topConstraint

        progressView.makeConstraints { v in
            v.heightAnchorConstraintTo(5)
            v.edgesConstraintToSuperview(edges: .horizontal)
            v.bottomAnchorConstraintTo(line.topAnchor)
        }
        
        // TODO: 사진 첨부 여부에 따라 버튼 추가
        
        // TODO: 멀티 선택 여부에 따라 카운트 추가 
    }
}
