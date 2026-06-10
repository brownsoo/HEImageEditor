//
//  AlbumListSkeletonView.swift
//  HEImagePicker
//
//  앨범 목록을 불러오는 동안 표시하는 스켈레톤(shimmer) 플레이스홀더 뷰.
//  실제 앨범 그리드(`AlbumListViewController`)의 셀 레이아웃을 모방한다.
//

import UIKit

/// 앨범 그리드 모양의 스켈레톤 플레이스홀더.
///
/// 화면 폭에 맞춰 셀 그리드를 계산하고, 각 셀의 썸네일/제목/개수 영역을
/// 둥근 사각형으로 채운 뒤 좌→우로 흐르는 shimmer 애니메이션을 입힌다.
final class AlbumListSkeletonView: UIView {

    // MARK: - Layout constants (AlbumListViewController 와 동일하게 유지)

    private let cellSpacing: CGFloat = 12
    private let sectionInset = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
    private let thumbnailCornerRadius: CGFloat = 8
    private let titleBarHeight: CGFloat = 12
    private let countBarHeight: CGFloat = 10
    private let cellHeightRatio: CGFloat = 202.0 / 158.0

    // MARK: - Layers

    /// shimmer 그라데이션. `shapeMaskLayer` 로 플레이스홀더 모양만 노출한다.
    private let gradientLayer = CAGradientLayer()
    /// 플레이스홀더(썸네일/바) 모양을 합친 마스크.
    private let shapeMaskLayer = CAShapeLayer()

    private let shimmerAnimationKey = "he.skeleton.shimmer"

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.mask = shapeMaskLayer
        layer.addSublayer(gradientLayer)
        applyColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // 레이아웃 변경 시 애니메이션이 끊기지 않도록 암묵적 애니메이션을 끈다.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        shapeMaskLayer.path = makePlaceholderPath().cgPath
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyColors()
        }
    }

    // MARK: - Animation control

    func startAnimating() {
        isHidden = false
        guard gradientLayer.animation(forKey: shimmerAnimationKey) == nil else { return }
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: shimmerAnimationKey)
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: shimmerAnimationKey)
        isHidden = true
    }

    // MARK: - Helpers

    private func applyColors() {
        let base = Self.baseColor.resolvedColor(with: traitCollection).cgColor
        let highlight = Self.highlightColor.resolvedColor(with: traitCollection).cgColor
        gradientLayer.colors = [base, highlight, base]
        gradientLayer.locations = [0.0, 0.5, 1.0]
    }

    /// 현재 폭 기준으로 보이는 모든 셀의 플레이스홀더(썸네일+제목바+개수바) 경로를 합쳐 반환한다.
    private func makePlaceholderPath() -> UIBezierPath {
        let path = UIBezierPath()
        guard bounds.width > 0, bounds.height > 0 else { return path }

        let columns = numberOfColumns
        let totalSpacing = (columns - 1) * cellSpacing + sectionInset.left + sectionInset.right
        let cellWidth = max(0, (bounds.width - totalSpacing) / columns)
        let cellHeight = cellWidth * cellHeightRatio
        guard cellWidth > 0 else { return path }

        // 화면을 채울 만큼의 행 수(+1 로 하단 잘림 셀까지 표현).
        let rowStride = cellHeight + cellSpacing
        let availableHeight = bounds.height - sectionInset.top
        let rows = max(1, Int(ceil(availableHeight / rowStride)) + 1)
        let columnCount = Int(columns)

        for row in 0..<rows {
            for column in 0..<columnCount {
                let originX = sectionInset.left + CGFloat(column) * (cellWidth + cellSpacing)
                let originY = sectionInset.top + CGFloat(row) * rowStride
                appendCellShapes(to: path, originX: originX, originY: originY, cellWidth: cellWidth)
            }
        }
        return path
    }

    private func appendCellShapes(to path: UIBezierPath, originX: CGFloat, originY: CGFloat, cellWidth: CGFloat) {
        // 썸네일(정사각형)
        let thumbnail = CGRect(x: originX, y: originY, width: cellWidth, height: cellWidth)
        path.append(UIBezierPath(roundedRect: thumbnail, cornerRadius: thumbnailCornerRadius))

        // 제목 바 (썸네일 하단 중앙)
        let titleWidth = cellWidth * 0.6
        let titleY = thumbnail.maxY + 10
        let title = CGRect(x: originX + (cellWidth - titleWidth) / 2, y: titleY, width: titleWidth, height: titleBarHeight)
        path.append(UIBezierPath(roundedRect: title, cornerRadius: titleBarHeight / 2))

        // 개수 바 (제목 하단 중앙). 실제 셀의 titleLb→countLb 간격(4pt)과 동일하게 맞춘다.
        let countWidth = cellWidth * 0.34
        let countY = title.maxY + 4
        let count = CGRect(x: originX + (cellWidth - countWidth) / 2, y: countY, width: countWidth, height: countBarHeight)
        path.append(UIBezierPath(roundedRect: count, cornerRadius: countBarHeight / 2))
    }

    private var numberOfColumns: CGFloat {
        let orientation = UIApplication.shared.he.findKeyWindow()?.windowScene?.interfaceOrientation ?? .portrait
        return (orientation == .landscapeLeft || orientation == .landscapeRight) ? 4 : 2
    }

    // MARK: - Colors

    private static let baseColor = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.90, alpha: 1)
    }

    private static let highlightColor = UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.30, alpha: 1) : UIColor(white: 0.97, alpha: 1)
    }
}
