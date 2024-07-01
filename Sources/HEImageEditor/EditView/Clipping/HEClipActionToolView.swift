//
//  HEClipToolView.swift
//  HEImageEditor
//
//  Created by hyonsoo on 6/8/24.
//

import Foundation
import UIKit

protocol HEClipToolViewDelegate: AnyObject {
    func clipRatioSelected(sender: HEClipActionToolView, ratio: HEImageClipRatio)
    func clipRotateSelected(sender: HEClipActionToolView)
}

class HEClipActionToolView: UIView {
    enum ClipActionSection: Int {
        case rotate
        case separator
        case crop
    }
    
    static let viewHeight: CGFloat = 84
    
    weak var delegate: HEClipToolViewDelegate?
    
    private var actionItems: [ClipActionSection: [HEImageClipRatio]]
    private var clipActionColContentViewWidth: CGFloat
    private var selectedRatio: HEImageClipRatio
    private var clipActionColView: UICollectionView!
    
    required init(clipRatios: [HEImageClipRatio], originImageSize: CGSize, selectedRatio: HEImageClipRatio?) {
        actionItems = [:]
        actionItems[.rotate] = [] // 회전
        actionItems[.separator] = [] // 구분 선
        actionItems[.crop] = clipRatios // 크롭
        // 원본 비율 설정
        actionItems[.crop]?.first(where: { $0 == .origin })?.whRatio = originImageSize.width / originImageSize.height
        
        let spaceBetweenCell: CGFloat = 20
        let numberOfClipItems: CGFloat = CGFloat(self.actionItems[.crop]?.count ?? 0)
        let totalWidth = (ClipActionCell.itemSize.width * (numberOfClipItems + 1)) + ClipActionSeparatorCell.itemSize.width // 1 => rotate
        let totalSpacingWidth = spaceBetweenCell * (numberOfClipItems - 1)
        clipActionColContentViewWidth = totalWidth + totalSpacingWidth
        self.selectedRatio = selectedRatio ?? .custom
        
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        clipActionColView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        clipActionColView.delegate = self
        clipActionColView.dataSource = self
        clipActionColView.backgroundColor = .clear
        clipActionColView.isHidden = actionItems.count < 1
        clipActionColView.showsHorizontalScrollIndicator = false
        clipActionColView.backgroundColor = .black.withAlphaComponent(0.7)
        self.addSubview(clipActionColView)
        clipActionColView.register(ClipActionCell.self, forCellWithReuseIdentifier: ClipActionCell.he.identifier)
        clipActionColView.register(ClipActionSeparatorCell.self,  forCellWithReuseIdentifier: ClipActionSeparatorCell.he.identifier)
        
        clipActionColView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clipActionColView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            clipActionColView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            clipActionColView.topAnchor.constraint(equalTo: self.topAnchor),
            clipActionColView.bottomAnchor.constraint(equalTo: self.bottomAnchor).withPriority(.defaultHigh)
        ])
    }
    
    func selectRatio(_ ratio: HEImageClipRatio, animated: Bool) {
        if actionItems.count > 1, let index = actionItems[.crop]?.firstIndex(where: { $0 == ratio }) {
            clipActionColView.scrollToItem(at: IndexPath(row: index, section: ClipActionSection.crop.rawValue), at: .centeredHorizontally, animated: animated)
        }
        self.selectedRatio = ratio
    }
    
    func show(animate: Bool = true) {
        if animate {
            self.isHidden = false
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseOut], animations: {
                self.alpha = 1
            })
            UIView.animate(withDuration: 0.2, delay: 0.2, options: [.curveEaseOut], animations: {
                self.transform = .identity
            })
        } else {
            self.isHidden = false
            self.transform = .identity
            self.alpha = 1
        }
    }
    
    func hide(animate: Bool = true) {
        if animate {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear], animations: {
                self.transform = CGAffineTransform(translationX: 0, y: 12)
                self.alpha = 0
            }) { _ in
                self.isHidden = true
            }
        } else {
            self.alpha = 0
            self.isHidden = true
            self.transform = CGAffineTransform(translationX: 0, y: 12)
        }
    }
}


// MARK: 액션 트레이 - UICollectionViewDataSource, UICollectionViewDelegate
extension HEClipActionToolView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return actionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = ClipActionSection(rawValue: section) else { return 0 }
        switch section {
        case .rotate, .separator:
            return 1
        case .crop:
            return actionItems[section]?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = ClipActionSection(rawValue: indexPath.section) else { return UICollectionViewCell() }
        let ratios = actionItems[section] ?? []
        switch section {
        case .rotate, .crop:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipActionCell.he.identifier, for: indexPath) as! ClipActionCell
            if section == .rotate {
                cell.configureCell(title: localLanguageTextValue(.rotate),
                                   image: UIImage.he.getImage("icEditRotate"),
                                   ratio: .origin)
                cell.imageView.highlightedImage = UIImage.he.getImage("icEditRotate")?.withTintColor(.he.rgba(71, 120, 222))
            } else {
                let ratio = ratios[indexPath.row]
                cell.configureCell(title: localLanguageTextValue(HELocalLanguageKey(rawValue: ratio.title)),
                                   image: UIImage.he.getImage(ratio.iconName),
                                   ratio: ratio)
            }
            return cell
        case .separator:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipActionSeparatorCell.he.identifier, for: indexPath)
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let section = ClipActionSection(rawValue: indexPath.section) else { return false }
        return section != .separator
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = ClipActionSection(rawValue: indexPath.section) else { return }
        if section == .separator {
            return
        }
        let cell = collectionView.cellForItem(at: indexPath) as? ClipActionCell
        if section == .rotate {
            self.delegate?.clipRotateSelected(sender: self)
            cell?.imageView.isHighlighted = true
            return
        }
        let ratios = actionItems[section] ?? []
        let ratio = ratios[indexPath.row]
        guard ratio != selectedRatio else {
            return
        }
        selectedRatio = ratio
        clipActionColView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.delegate?.clipRatioSelected(sender: self, ratio: ratio)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let section = ClipActionSection(rawValue: indexPath.section) else { return }
        let cell = collectionView.cellForItem(at: indexPath) as? ClipActionCell
        if section == .rotate {
            cell?.imageView.isHighlighted = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = .white.withAlphaComponent(0.1)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = nil
    }
}

extension HEClipActionToolView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let section = ClipActionSection(rawValue: section) else { return 0 }
        switch section {
        case .crop:
            return 20
        case .rotate:
            return 0
        case .separator:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let section = ClipActionSection(rawValue: indexPath.section) else { return .zero }
        switch section {
        case .separator:
            return ClipActionSeparatorCell.itemSize
        default:
            return ClipActionCell.itemSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let section = ClipActionSection(rawValue: section) else { return .zero }
        if section == .separator {
            return .init(top: 0, left: 0, bottom: 4, right: 0)
        }
        let inset = (collectionView.frame.width - clipActionColContentViewWidth) / 2
        if section == .rotate {
            return UIEdgeInsets(top: 0, left: inset, bottom: 4, right: 0)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 4, right: inset)
    }
    
}



// MARK: Cell

final class ClipActionCell: UICollectionViewCell {
    
    static let itemSize  = CGSize(width: 54, height: 60)
    
    var imageView: UIImageView!
    var titleLabel: UILabel!
    var ratio: HEImageClipRatio!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        imageView.contentMode = .scaleAspectFill
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor(white: 204 / 255.0, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        let sv = UIStackView(arrangedSubviews: [imageView, titleLabel])
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .center
        sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.setContentHuggingPriority(.required, for: .vertical)
        sv.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(sv)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.heightAnchor.constraint(equalToConstant: 12).withPriority(.defaultLow),
            sv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            sv.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 4),
            sv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).withPriority(.defaultHigh),
//            sv.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).withPriority(.defaultHigh),
        ])
        
    }
    
    func configureCell(title: String, image: UIImage?, ratio: HEImageClipRatio) {
        imageView.image = image
        titleLabel.text = title
        self.ratio = ratio
        
        setNeedsLayout()
    }
}

final class ClipActionSeparatorCell: UICollectionViewCell {
    
    static let itemSize  = CGSize(width: 33, height: 60)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    private func setupUI() {
        let line = UIView()
        line.backgroundColor = .white.withAlphaComponent(0.08)
        contentView.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        line.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)
        NSLayoutConstraint.activate([
            line.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            line.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            line.widthAnchor.constraint(equalToConstant: 1)
        ])
    }
    
}

