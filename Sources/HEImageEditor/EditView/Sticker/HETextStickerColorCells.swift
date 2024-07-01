//
//  HETextColorCell.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/19/24.
//

import UIKit

class HETextColorCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HEImageEditor.HETextColorCell"
    
    lazy var colorView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        view.image = UIImage.he.getImage("edit_color_white") ?? UIImage(systemName: "circle.fill")
        view.highlightedImage = UIImage.he.getImage("edit_color_select_white") ?? UIImage(systemName: "record.circle")
        return view
    }()
    
    var color: UIColor = .white {
        willSet {
            colorView.image = colorView.image?.withTintColor(newValue)
            colorView.highlightedImage = colorView.highlightedImage?.withTintColor(newValue)
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
    
    lazy var colorView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        return view
    }()
    
    private lazy var noneImage: UIImage? = {
        UIImage.he.getImage("edit_color_bg_none") ?? UIImage(systemName: "nosign")?.withTintColor(.white)
    }()
    
    var color: UIColor = .clear {
        willSet {
            if newValue == UIColor.clear {
                colorView.image = noneImage
            } else {
                colorView.image = (UIImage.he.getImage("edit_color_white") ?? UIImage(systemName: "circle.fill"))?.withTintColor(newValue)
                colorView.highlightedImage = (UIImage.he.getImage("edit_color_select_white") ?? UIImage(systemName: "record.circle"))?.withTintColor(newValue)
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
