//
//  LibraryCell.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//


import UIKit

class MultipleSelectionIndicator: UIView {
    
    let circle = UIView()
    let label = UILabel()
    var selectionColor = UIColor.ypSystemBlue

    convenience init() {
        self.init(frame: .zero)
        
        let size: CGFloat = 24
        addSubview(circle)
        addSubview(label)
        
        circle.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all, priority: .defaultHigh)
            v.sizeAnchorConstraintTo(size)
        }
        label.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        
        circle.layer.cornerRadius = size / 2.0
        label.textAlignment = .center
        label.textColor = .white
        label.font = PickerConfig.fonts.multipleSelectionIndicatorFont
        
        set(number: nil)
    }
    
    func set(number: Int?) {
        label.isHidden = (number == nil)
        if let number = number {
            circle.backgroundColor = selectionColor
            circle.layer.borderColor = UIColor.white.cgColor
            circle.layer.borderWidth = 2
            label.text = "\(number)"
        } else {
            circle.backgroundColor = UIColor.white.withAlphaComponent(0.4)
            circle.layer.borderColor = UIColor.white.cgColor
            circle.layer.borderWidth = 2
            label.text = ""
        }
    }
}

class LibraryViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HE.LibraryViewCell"
    
    var representedAssetIdentifier: String!
    let imageView = UIImageView()
    var imageLoader: (() async -> UIImage?)?
    let durationLabel = UILabel()
    let selectionOverlay = UIView()
    let multipleSelectionIndicator = MultipleSelectionIndicator()
    let captionLabel = UILabel()
    var captionLabelFilledHeight: NSLayoutConstraint?
    private var imageLoadTask: Task<(), Never>?
    
    func loadImage() {
        imageLoadTask?.cancel()
        imageLoadTask = Task {
            let image = await imageLoader?()
            if Task.isCancelled { return }
            imageView.image = image
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        contentView.addSubview(captionLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(multipleSelectionIndicator)
        
        imageView.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        selectionOverlay.makeConstraints { v in
            v.edgesConstraintToSuperview(edges: .all)
        }
        captionLabel.makeConstraints { v in
            v.setContentHuggingPriority(.defaultLow, for: .horizontal)
            v.setContentHuggingPriority(.required, for: .vertical)
            v.setContentCompressionResistancePriority(.required, for: .vertical)
            v.edgesConstraintToSuperview(edges: [.horizontal, .bottom])
            v.heightAnchor.constraint(equalToConstant: 0).with(priority: .defaultLow).isActive = true
            
            captionLabelFilledHeight = v.heightAnchor.constraint(equalToConstant: 20).with(priority: .required)
            captionLabelFilledHeight?.isActive = false
        }
        durationLabel.makeConstraints { v in
            v.trailingAnchorConstraintToSuperview(-5)
            v.bottomAnchorConstraintTo(captionLabel.topAnchor, constant: -5)
        }
        multipleSelectionIndicator.makeConstraints { v in
            v.topAnchorConstraintToSuperview(4)
            v.trailingAnchorConstraintToSuperview(-4)
            
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        captionLabel.textColor = UIColor(white: 246.0 / 255.0, alpha: 1)
        captionLabel.font = PickerConfig.fonts.captionFont
        captionLabel.textAlignment = .center
        captionLabel.backgroundColor = .black.withAlphaComponent(0.6)
        durationLabel.textColor = .white
        durationLabel.font = PickerConfig.fonts.durationFont
        durationLabel.isHidden = true
        selectionOverlay.backgroundColor = .white
        selectionOverlay.alpha = 0
        backgroundColor = .ypSecondarySystemBackground
        setAccessibilityInfo()
    }

    override var isSelected: Bool {
        didSet { refreshSelection() }
    }
    
    override var isHighlighted: Bool {
        didSet { refreshSelection() }
    }
    
    private func refreshSelection() {
        let showOverlay = isSelected || isHighlighted
        selectionOverlay.alpha = showOverlay ? 0.6 : 0
    }

    private func setAccessibilityInfo() {
        isAccessibilityElement = true
        self.accessibilityIdentifier = "HE.LibraryViewCell"
        self.accessibilityLabel = "Library Image"
    }
}
