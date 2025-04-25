//
//  HEImageStickerTrayView.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/11/24.
//

import UIKit

@objc
public protocol HEImageStickerTrayViewDataSource {
    @objc func hasMosaicSticker(_ trayView: HEImageStickerTrayView) -> Bool
    @objc func imageStickerTrayView(_ trayView: HEImageStickerTrayView, numberOfItemsInSection section: Int) -> Int
    @objc func imageStickerTrayView(_ trayView: HEImageStickerTrayView, stickerForItemAt indexPath: IndexPath) -> HEImageSticker
    @objc optional func numberOfSections(in trayView: HEImageStickerTrayView) -> Int
    @objc optional func allStickers(_ trayView: HEImageStickerTrayView, numberOfItemsInSection section: Int) -> [HEImageSticker]
    /// 얼굴 이미지 스티커 전용 
    @objc optional func allStickersOnFace(_ trayView: HEImageStickerTrayView) -> [HEImageSticker]
}

public class HEImageStickerTrayView: UIView, HEImageStickerTray {
    
    static let baseViewH: CGFloat = EditorConfig.imageStickerTrayHeight
    
    public var selectImageStickerBlock: ((HEImageSticker) -> Void)?
    public var hideBlock: ((Bool) -> Void)?
    public var hasMosaicSticker: Bool {
        return dataSource?.hasMosaicSticker(self) ?? false
    }
    
    public weak var dataSource: HEImageStickerTrayViewDataSource?
    
    private var baseView: UIView!
    private var collectionView: UICollectionView!
    private var trayBottomConstraint: NSLayoutConstraint!
    private var trayHeightConstraint: NSLayoutConstraint!
    
    deinit {
        lg.trace()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.clipsToBounds = true
        
        self.baseView = UIView()
        self.addSubview(self.baseView)
        let baseView = self.baseView!
        baseView.backgroundColor = .black.withAlphaComponent(05)
        baseView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            trayBottomConstraint = it.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: Self.baseViewH)
            trayHeightConstraint = it.heightAnchor.constraint(equalToConstant: Self.baseViewH)
            NSLayoutConstraint.activate([
                it.leftAnchor.constraint(equalTo: self.leftAnchor),
                it.rightAnchor.constraint(equalTo: self.rightAnchor),
                trayBottomConstraint,
                trayHeightConstraint,
            ])
        }
        
        
        let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        baseView.addSubview(visualView)
        visualView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.leftAnchor.constraint(equalTo: baseView.leftAnchor),
                it.rightAnchor.constraint(equalTo:baseView.rightAnchor),
                it.topAnchor.constraint(equalTo: baseView.topAnchor),
                it.bottomAnchor.constraint(equalTo: baseView.bottomAnchor)
            ])
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 16, left: 18, bottom: 32, right: 18)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.estimatedItemSize = CGSize(width: 44, height: 44)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        baseView.addSubview(self.collectionView)
        self.collectionView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.leftAnchor.constraint(equalTo: baseView.leftAnchor),
                it.rightAnchor.constraint(equalTo:baseView.rightAnchor),
                it.topAnchor.constraint(equalTo: baseView.topAnchor),
                it.bottomAnchor.constraint(equalTo: baseView.bottomAnchor)
            ])
        }
        
        self.collectionView.register(ImageStickerCell.self, forCellWithReuseIdentifier: ImageStickerCell.reuseIdentifier)
        
    }
    
    private var shouldShow = false
    
    public func show(in parent: UIView, frame: CGRect) {
        shouldShow = true
        if self.superview !== parent {
            self.removeFromSuperview()
            parent.addSubview(self)
            self.frame = frame
            parent.layoutIfNeeded()
        }
//        trace()
        self.isHidden = false
        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState]) {
            self.trayBottomConstraint.constant = 0
            self.layoutIfNeeded()
        }
    }
    
    public func hide(instantly: Bool) {
//        trace()
        shouldShow = false
        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState]) {
            self.trayBottomConstraint.constant = Self.baseViewH
            self.superview?.layoutIfNeeded()
        } completion: { completed in
//            trace(completed)
            if completed && !self.shouldShow {
                self.hideBlock?(instantly)
                self.isHidden = true
            }
        }

    }
    
    public func randomStickerOnFace(inSection section: Int) -> HEImageSticker? {
        guard let dataSource else { return nil }
        
        if let allStickers = dataSource.allStickersOnFace?(self) {
            return allStickers.randomElement()
        }
        
        if let allStickers = dataSource.allStickers?(self, numberOfItemsInSection: section).filter({ !$0.isSpecialSticker }) {
            return allStickers.randomElement()
        }
        
        let total = dataSource.imageStickerTrayView(self, numberOfItemsInSection: section)
        if let random = (0..<total).randomElement() {
            return dataSource.imageStickerTrayView(self, stickerForItemAt: IndexPath(row: random, section: section))
        }
        return nil
    }
    
}


extension HEImageStickerTrayView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        return !self.baseView.frame.contains(location)
    }
    
}


extension HEImageStickerTrayView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let dataSource else {
            return 1
        }
        return dataSource.numberOfSections?(in: self) ?? 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource else {
            return 0
        }
        return dataSource.imageStickerTrayView(self, numberOfItemsInSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageStickerCell.reuseIdentifier, for: indexPath) as! ImageStickerCell
        
        let sticker = self.dataSource?.imageStickerTrayView(self, stickerForItemAt: indexPath)
        
        if let cached = sticker?.cachedImage {
            cell.imageView.image = cached
        } else {
            cell.imageView.image = nil
            Task(priority: .userInitiated) {
                let image = await sticker?.imageLoader()
                cell.imageView.image = image
                sticker?.cachedImage = image
            }
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sticker = self.dataSource?.imageStickerTrayView(self, stickerForItemAt: indexPath) else {
            return
        }
        self.selectImageStickerBlock?(sticker)
    }
    
}


class ImageStickerCell: UICollectionViewCell {
    static let reuseIdentifier = "HEImageSticker.ImageStickerCell"
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.also { it in
            it.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                it.widthAnchor.constraint(equalToConstant: 40),
                it.heightAnchor.constraint(equalToConstant: 40),
                it.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                it.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
