//
//  AlbumListViewController.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/3/24.
//

import UIKit
import Photos
import HECommon

final class AlbumListViewController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        PickerConfig.hidesStatusBar
    }
    
    var didSelectAlbum: ((HEAlbum) -> Void)?
    var albums = [HEAlbum]()
    let albumsManager: HEAlbumsManager
    
    private let skeletonView = AlbumListSkeletonView()
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
        orientation = UIApplication.shared.he.findKeyWindow()?.windowScene?.interfaceOrientation ?? .portrait
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collView.collectionViewLayout.invalidateLayout()
    }
    
    func fetchAlbumsInBackground() {
        skeletonView.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {return }
            var albums: [HEAlbum] = self.albumsManager.fetchAlbums()
            if albums.isEmpty {
                albums = [HEAlbum(thumbnail: nil,
                                  title: PickerConfig.wordings.all,
                                  numberOfItems: 0,
                                  collection: nil)]
            }
            self.albums = albums
            DispatchQueue.main.async {
                self.skeletonView.stopAnimating()
                self.collView.isHidden = false
                self.collView.reloadData()
            }
        }
    }
    
    @objc
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func setupUI() {
        view.backgroundColor = .offWhiteOrBlack
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: PickerConfig.icons.backButtonIcon,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
        
        navigationController?.navigationBar.titleTextAttributes = [.font: PickerConfig.fonts.navigationBarTitleFont,
                                                                   .foregroundColor: PickerConfig.colors.albumTitleColor]
        navigationController?.navigationBar.barTintColor = PickerConfig.colors.albumBarTintColor
        navigationController?.navigationBar.tintColor = PickerConfig.colors.albumTintColor
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = minimumCellSpacing
        layout.minimumInteritemSpacing = minimumCellSpacing
        layout.sectionInset = UIEdgeInsets(top: 20, left: 16, bottom: 40, right: 16)
        let coll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        //coll.contentInset = .zero
        coll.backgroundColor = .clear
        coll.showsHorizontalScrollIndicator = false
        coll.register(AlbumListCell.self, forCellWithReuseIdentifier: AlbumListCell.reuseIdentitifer)
        coll.allowsSelection = true
        coll.isPagingEnabled = false
        coll.dataSource = self
        coll.delegate = self
        view.addSubview(coll)
        self.collView = coll

        coll.isHidden = true
//        coll.frame = view.frame
        coll.makeConstraints { v in
            v.topAnchorConstraintTo(view.safeAreaLayoutGuide.topAnchor)
            v.leadingAnchorConstraintToSuperview()
            v.trailingAnchorConstraintToSuperview()
            v.bottomAnchorConstraintToSuperview()
        }

        // 앨범 로딩 중 표시할 스켈레톤. 그리드와 동일한 영역을 덮고, 로딩이 끝나면 숨겨진다.
        view.addSubview(skeletonView)
        skeletonView.makeConstraints { v in
            v.topAnchorConstraintTo(view.safeAreaLayoutGuide.topAnchor)
            v.leadingAnchorConstraintToSuperview()
            v.trailingAnchorConstraintToSuperview()
            v.bottomAnchorConstraintToSuperview()
        }
    }
}


extension AlbumListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumListCell.reuseIdentitifer, for: indexPath) as! AlbumListCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! AlbumListCell
        let album = albums[indexPath.row]
        cell.thumbnailIv.backgroundColor = .ypSystemGray
        cell.thumbnailIv.image = album.thumbnail
        cell.titleLb.text = album.title
        cell.countLb.text = "\(album.numberOfItems)"
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
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpacing = interSpacing + layout.sectionInset.left + layout.sectionInset.right
        let width = (collectionView.frame.width - totalSpacing) / columns
        return CGSize(width: width, height: width * 202.0 / 158.0)
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
            v.backgroundColor = UIColor { (trait: UITraitCollection) -> UIColor in
                trait.userInterfaceStyle == .dark ? UIColor.secondarySystemGroupedBackground : UIColor(white: 238 / 255.0, alpha: 1)
            }
            NSLayoutConstraint.activate([
                v.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1),
                v.heightAnchor.constraint(equalTo: v.widthAnchor, multiplier: 1),
                v.topAnchor.constraint(equalTo: contentView.topAnchor),
                v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
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
        titleLb.textColor = UIColor { (trait: UITraitCollection) -> UIColor in
            trait.userInterfaceStyle == .dark ? UIColor.label : UIColor(white: 51.0 / 255.0, alpha: 1)
        }
        
        countLb.font = PickerConfig.fonts.albumCellNumberOfItemsFont
        countLb.textColor = UIColor { (trait: UITraitCollection) -> UIColor in
            trait.userInterfaceStyle == .dark ? UIColor.secondaryLabel : UIColor(white: 187 / 255, alpha: 1)
        }
    }
}
