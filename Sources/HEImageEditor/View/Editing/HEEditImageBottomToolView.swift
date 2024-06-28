//
//  HEEditImageBottomToolView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/10/24.
//

import Foundation
import UIKit

public protocol HEEditToolView: UIView {
    func unselectTool()
    func selectTool(_ tool: HEConfiguration.EditTool, dispatchingEvent: Bool)
}
public extension HEEditToolView {
    func selectTool(_ tool: HEConfiguration.EditTool) {
        self.selectTool(tool, dispatchingEvent: true)
    }
}

open class HEEditImageBottomToolView: UIView, HEEditToolView {
    
    public static let height: CGFloat = 72
    public static let itemSize = CGSize(width: 54, height: 56)
    public static let padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    public static let minimumInterspacing: CGFloat = 20
    
    public let tools: [HEConfiguration.EditTool]
    public var toolSelectListener: ((HEConfiguration.EditTool) -> Void)?
    public private(set) var selectedTool: HEConfiguration.EditTool?
    
    var interitemSpacing: CGFloat = 20
    
    public init(tools: [HEConfiguration.EditTool]) {
        self.tools = tools
        super.init(frame: .zero)
        setupUI()
    }
    
    public required init?(coder: NSCoder) { // TODO: check coder
        let tools = coder.decodeObject(forKey: "tools") as? [HEConfiguration.EditTool]
        self.tools = tools ?? []
        super.init(coder: coder)
    }
    
    open override func encode(with coder: NSCoder) {
        coder.encode(tools, forKey: "tools")
        super.encode(with: coder)
    }
    
    open func selectTool(_ tool: HEConfiguration.EditTool, dispatchingEvent: Bool) {
        selectedTool = tool
        if dispatchingEvent {
            toolSelectListener?(tool)
        }
        if let row = tools.firstIndex(where: { $0 == tool }) {
            collView.selectItem(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        } else {
            collView.reloadData()
        }
    }
    
    open func unselectTool() {
        let tool = selectedTool
        selectedTool = nil
        if let tool, let row = tools.firstIndex(where: { $0 == tool }) {
            collView.deselectItem(at: IndexPath(row: row, section: 0), animated: true)
        } else {
            collView.reloadData()
        }
    }
    
    private var collView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.backgroundColor = .clear
        coll.showsHorizontalScrollIndicator = false
        HEEditToolCell.he.register(coll)
        return coll
    }()
    
    
    func setupUI() {
        collView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collView)
        NSLayoutConstraint.activate([
            collView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collView.topAnchor.constraint(equalTo: self.topAnchor),
            collView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
        ])
        collView.contentInsetAdjustmentBehavior = .never
        collView.delegate = self
        collView.dataSource = self
    }
    
    private func updateCollContentInset() {
        let toolsCount = CGFloat(tools.count)
        if toolsCount < 1 {
            return
        }
        
        let minimumWidth = toolsCount * Self.itemSize.width + (Self.minimumInterspacing * (toolsCount - 1))
        let fullSpace = self.frame.width
        let space = fullSpace - Self.padding.width
        
        if minimumWidth < space {
            let remain = fullSpace - Self.itemSize.width * toolsCount
            let equalSpace = remain / (toolsCount + 1) // 양쪽 포함 공백
            let sidePadding = equalSpace * 2 * CGFloat(47.0 / 52.0) // 양쪽 여백 비율 : 47/52
            interitemSpacing = (remain - sidePadding) / (toolsCount - 1)
        } else {
            interitemSpacing = Self.minimumInterspacing
        }
        let toolsWidth = (Self.itemSize.width + interitemSpacing) * toolsCount - interitemSpacing
        let inset = (fullSpace - toolsWidth) / 2
        self.collView.contentInset = UIEdgeInsets(top: 0,
                                                            left: max(inset, Self.padding.left),
                                                            bottom: 0,
                                                            right: max(inset, Self.padding.right))
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateCollContentInset()
    }
}

extension HEEditImageBottomToolView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tools.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HEEditToolCell.he.identifier, for: indexPath) as! HEEditToolCell
        
        let toolType = tools[indexPath.row]
        cell.toolType = toolType
        cell.iconView.isHighlighted = toolType == selectedTool
        cell.titleLabel.isHighlighted = toolType == selectedTool
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = nil
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let toolType = tools[indexPath.row]
        self.toolSelectListener?(toolType)
    }
}

extension HEEditImageBottomToolView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Self.itemSize
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        self.interitemSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        self.interitemSpacing
    }
}

class HEEditToolCell: UICollectionViewCell {
    
    var toolType: HEConfiguration.EditTool = .draw {
        didSet {
            badgeView.isHidden = true
            var icon: UIImage?
            switch toolType {
            case .draw:
                icon = UIImage(systemName: "pencil.line")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                
            case .clip:
                icon = .he.getImage("icEditMnCutting") ?? UIImage(systemName: "crop")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                
            case .imageSticker:
                icon = .he.getImage("icEditMnSticker") ?? UIImage(systemName: "face.smiling")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                badgeView.image = .he.getImage("editBadgeAi")
                badgeView.frame = CGRect(x: 0, y: 0, width: 20, height: 16)
                // 아이콘 중앙에서 5, -2 에 위치
                badgeBottomConstraint.constant = -2
                badgeLeftConstraint.constant = 5
                badgeView.isHidden = false
                
            case .textSticker:
                icon = UIImage.he.getImage("icEditMnText") ?? UIImage(systemName: "t.square.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                
            case .mosaicDraw:
                icon = UIImage(systemName: "mosaic")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                
            case .filter:
                icon = UIImage(systemName: "camera.filters")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                
            case .adjust:
                icon = UIImage(systemName: "slider.vertical.3")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            }
            
            iconView.image = icon
            
            if let color = UIColor.he.toolIconHighlightedColor {
                iconView.highlightedImage = icon?.withTintColor(color)
                titleLabel.highlightedTextColor = color
            } else {
                iconView.highlightedImage = icon
            }
            
            titleLabel.text = toolType.label
        }
    }
    lazy var badgeView = UIImageView()
    lazy var iconView = UIImageView()
    lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .he.rgba(204, 204, 204)
        lb.font = .systemFont(ofSize: 11, weight: .bold)
        lb.textAlignment = .center
        return lb
    }()
    
    private var badgeBottomConstraint: NSLayoutConstraint!
    private var badgeLeftConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconView)
        contentView.addSubview(badgeView)
        badgeView.isHidden = true
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        badgeBottomConstraint = badgeView.bottomAnchor.constraint(equalTo: iconView.centerYAnchor)
        badgeLeftConstraint = badgeView.leftAnchor.constraint(equalTo: iconView.centerXAnchor)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            badgeBottomConstraint,
            badgeLeftConstraint,
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
