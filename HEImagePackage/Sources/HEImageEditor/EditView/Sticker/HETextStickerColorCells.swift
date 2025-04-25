//
//  HETextColorCell.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/19/24.
//

import UIKit

class HETextColorCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HEImageEditor.HETextColorCell"
    
    private lazy var normalIcon = UIImage.he.getImage("editColorWhite") ?? UIImage(systemName: "circle.fill")
    private lazy var selectIcon = UIImage.he.getImage("editColorSelectWhite") ?? UIImage(systemName: "record.circle")
    
    lazy var colorView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        view.image = normalIcon
        return view
    }()
    
    var color: UIColor = .white
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                colorView.image = selectIcon?.withTintColor(self.color)
            } else {
                colorView.image = normalIcon?.withTintColor(self.color)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorView.center = contentView.center
    }
}


class HETextFillColorCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HEImageEditor.HETextFillColorCell"
    
    private lazy var normalIcon = UIImage.he.getImage("editColorWhite") ?? UIImage(systemName: "circle.fill")
    private lazy var selectIcon = UIImage.he.getImage("editColorSelectWhite") ?? UIImage(systemName: "record.circle")
    
    var color: UIColor = .clear
    lazy var colorView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        return view
    }()
    
    private lazy var noneImage: UIImage? = {
        UIImage.he.getImage("editColorBgNone") ?? UIImage(systemName: "nosign")?.withTintColor(.white)
    }()
    
    override var isSelected: Bool {
        didSet {
            if self.color == .clear {
                colorView.image = noneImage
            } else {
                if isSelected {
                    colorView.image = selectIcon?.withTintColor(self.color)
                } else {
                    colorView.image = normalIcon?.withTintColor(self.color)
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        colorView.center = contentView.center
    }
}
