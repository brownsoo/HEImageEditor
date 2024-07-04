//
//  AlbumListViewController.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/3/24.
//

import UIKit
import Photos

final class AlbumListViewController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        PickerConfig.hidesStatusBar
    }
    
    var didSelectAlbum: ((HEAlbum) -> Void)?
    var albums = [HEAlbum]()
    let albumsManager: HEAlbumsManager
    
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var collView: UICollectionView!
    private var orientation: UIInterfaceOrientation = .portrait
    private let minimumCellSpacing: CGFloat = 12
    required init(albumsManager: HEAlbumsManager) {
        self.albumsManager = albumsManager
        super.init(nibName: nil, bundle: nil)
        title = PickerConfig.wordings.albumsTitle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAlbumsInBackground()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        orientation = UIApplication.shared.findKeyWindow()?.windowScene?.interfaceOrientation ?? .portrait
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collView.collectionViewLayout.invalidateLayout()
    }
    
    func fetchAlbumsInBackground() {
       spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.albums = self?.albumsManager.fetchAlbums() ?? []
            DispatchQueue.main.async {
                self?.spinner.stopAnimating()
                self?.collView.isHidden = false
                self?.collView.reloadData()
            }
        }
    }
    
    @objc
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func setupUI() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: imageFromBundle("icArrowRight"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        
        navigationController?.navigationBar.titleTextAttributes = [.font: PickerConfig.fonts.navigationBarTitleFont,
                                                                   .foregroundColor: PickerConfig.colors.albumTitleColor]
        navigationController?.navigationBar.barTintColor = PickerConfig.colors.albumBarTintColor
        navigationController?.navigationBar.tintColor = PickerConfig.colors.albumTintColor
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = minimumCellSpacing
        layout.minimumInteritemSpacing = minimumCellSpacing
        layout.sectionInset = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        coll.backgroundColor = .clear
        coll.showsHorizontalScrollIndicator = false
        coll.register(AlbumListCell.self, forCellWithReuseIdentifier: AlbumListCell.reuseIdentitifer)
        coll.allowsSelection = false
        coll.isPagingEnabled = true
        coll.dataSource = self
        coll.delegate = self
        view.addSubview(coll)
        self.collView = coll
        
        coll.isHidden = true
    }
}


extension AlbumListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let album = albums[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumListCell.reuseIdentitifer, for: indexPath) as! AlbumListCell
        cell.thumbnailIv.backgroundColor = .ypSystemGray
        cell.thumbnailIv.image = album.thumbnail
        cell.titleLb.text = album.title
        cell.countLb.text = "\(album.numberOfItems)"
        return cell
    }
}

extension AlbumListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectAlbum?(albums[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var columns: CGFloat
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            columns = 4
        } else {
            columns = 2
        }
        let interSpacing: CGFloat = (columns - 1) * minimumCellSpacing
        let totalSpacing = interSpacing + collectionView.contentInset.left + collectionView.contentInset.right
        let width = (collectionView.bounds.width - totalSpacing) / columns
        return CGSize(width: width, height: width)
    }
}


class AlbumListCell: UICollectionViewCell {
    
    static let reuseIdentitifer = "HE.AlbumListCell"
    
    let thumbnailIv = UIImageView()
    let titleLb = UILabel()
    let countLb = UILabel()
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(thumbnailIv)
        contentView.addSubview(titleLb)
        contentView.addSubview(countLb)
        
        thumbnailIv.makeConstraints { v in
            NSLayoutConstraint.activate([
                v.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1),
                v.heightAnchor.constraint(equalTo: v.widthAnchor, multiplier: 1),
                v.topAnchor.constraint(equalTo: v.topAnchor),
                v.leadingAnchor.constraint(equalTo: v.leadingAnchor)
            ])
        }
        
        titleLb.makeConstraints { v in
            v.setContentHuggingPriority(.required, for: .vertical)
            v.setContentCompressionResistancePriority(.required, for: .vertical)
            v.setContentHuggingPriority(.required, for: .horizontal)
            v.centerXAnchorConstraintTo(thumbnailIv)
            v.topAnchorConstraintTo(thumbnailIv.bottomAnchor, constant: 10)
        }
        
        countLb.makeConstraints { v in
            v.setContentHuggingPriority(.required, for: .vertical)
            v.setContentCompressionResistancePriority(.required, for: .vertical)
            v.setContentHuggingPriority(.required, for: .horizontal)
            v.centerXAnchorConstraintTo(thumbnailIv)
            v.topAnchorConstraintTo(titleLb.bottomAnchor, constant: 4)
            v.bottomAnchorConstraintToSuperview(priority: .defaultHigh)
        }
        
        thumbnailIv.contentMode = .scaleAspectFill
        thumbnailIv.layer.masksToBounds = true
        thumbnailIv.layer.cornerRadius = 8
        
        titleLb.numberOfLines = 1
        titleLb.lineBreakMode = .byTruncatingTail
        titleLb.font = PickerConfig.fonts.albumCellTitleFont
        titleLb.textColor = UIColor(white: 51.0 / 255.0, alpha: 1)
        countLb.font = PickerConfig.fonts.albumCellNumberOfItemsFont
        countLb.textColor = UIColor(white: 187 / 255, alpha: 1)
        
    }
}
