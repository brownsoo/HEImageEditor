//
//  ViewController.swift
//  Example
//
//  Created by long on 2020/11/23.
//  Changed by brownsoo on 2024/summer

import UIKit
import SwiftUI
import HECommon
import HEImageEditor
import HEImagePicker
import PhotosUI
import OrderedCollections

class ViewController: UIViewController {
//    var editImageToolView: UIView!
//    var editImageDrawToolSwitch: UISwitch!
//    var editImageClipToolSwitch: UISwitch!
//    var editImageImageStickerToolSwitch: UISwitch!
//    var editImageTextStickerToolSwitch: UISwitch!
//    var editImageMosaicToolSwitch: UISwitch!
//    var editImageFilterToolSwitch: UISwitch!
//    var editImageAdjustToolSwitch: UISwitch!
//    var resultImageView: UIImageView!
//    var originalImage: UIImage?
//    var resultImageEditState: HEEditState?
    let config = HEImageEditorConfiguration.default()
    
    private var editCancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let icon = UIImage(systemName: "chevron.backward")?.withTintColor(.white)
        btn.setImage(icon, for: .normal)
        btn.setImage(icon?.withTintColor(.lightGray), for: .disabled)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private var editDoneBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("완료", for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private var editUndoBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setImage(UIImage(systemName: "arrow.uturn.backward.circle"), for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private var editRedoBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setImage(UIImage(systemName: "arrow.uturn.forward.circle"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    var imageStickers: [HEImageSticker] = []
    
    lazy var imageStore = HESimpleEditImageStore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupUI()
        configImageEditor()
        
        
    }
    
    func configImageEditor() {
        
        let stickerTray = HEImageStickerTrayView()
        stickerTray.dataSource = self
        
        imageStickers.append(HEImageSticker.faceAiIcon)
        imageStickers.append(HEImageSticker.mosaicIcon)
        imageStickers.append(contentsOf: (1...18).map { (v) -> String in
            "imageSticker" + String(v)
        }.compactMap { name in
            HEImageSticker(id: name) {
                UIImage(named: name) ?? UIImage()
            }
        })
        
        HEImageEditorConfiguration.default()
            .clipRatios([.origin, .custom, .wh1x1, .wh4x3, .circle])
            .imageStickerTray(stickerTray)
    }
    
    
    func startEditSingleImage(_ image: UIImage, editState: HEEditState?) {
        HEEditImageViewController.showImageEditor(
            parent: self,
            image: image,
            editState: editState,
            delegate: self,
            topToolViewBuilder: makeTopToolBuilder(),
            clipImageBottomViewBuilder: { clipView in
                let bottom = HEClipBottomView()
                bottom.cancelClickListener = { [weak clipView] in clipView?.cancelEdit() }
                bottom.doneClickListener = { [weak clipView] in clipView?.doneEdit() }
                bottom.revertClickListener = { [weak clipView] in clipView?.revertEdit() }
                return (bottom, HEClipBottomView.estimateHeight)
            }
        )
    }
   
    
    func startEditMultipleImages(_ images: [HEEditImage]) {
        imageStore.clearAll()
        imageStore.addHEImages(images)
        let vc = HEImageEditorViewController(imageStore: imageStore,
                                            stickerDataSource: self)
        
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        present(vc, animated: true)
    }
}

extension ViewController: HEImageStickerTrayViewDataSource {
    
    func hasMosaicSticker(_ trayView: HEImageStickerTrayView) -> Bool {
        true
    }
    
    func imageStickerTrayView(_ trayView: HEImageStickerTrayView, numberOfItemsInSection section: Int) -> Int {
        imageStickers.count
    }
    
    func imageStickerTrayView(_ trayView: HEImageStickerTrayView, stickerForItemAt indexPath: IndexPath) -> HEImageSticker {
        imageStickers[indexPath.row]
    }
    
    func allStickers(_ trayView: HEImageStickerTrayView, numberOfItemsInSection section: Int) -> [HEImageSticker] {
        return imageStickers
    }
}

extension ViewController: HEImageEditorDelegate {
    
    func didCancelEditImages(_ editor: HEImageEditor) {
        debugPrint("== didCancelEditImages ==")
        if let picker = editor.navigationController as? HEImagePicker {
            picker.reload()
        }
    }
    
    func didFinishEditImages(_ editor: HEImageEditor) {
        debugPrint("== didFinishEditImages ==")
        if let picker = editor.navigationController as? HEImagePicker {
            picker.reload()
            picker.popToRootViewController(animated: true)
        } else {
            if let nc = editor.navigationController, nc.viewControllers.count > 1 {
                nc.popViewController(animated: true)
            } else {
                editor.dismiss(animated: true)
            }
        }
    }
    
    func confirmingResetEditImage(_ editor: HEImageEditor, hei: HEEditImage, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "현재 보이는 이미지를 원본으로 초기화 합니다.\n진행 하시겠습니까?", preferredStyle: .alert)
        DispatchQueue.main.async {
            let okayAction = UIAlertAction(title: "확인", style: .default, handler: { _ in completion(true) })
            alert.addAction(okayAction)
            alert.addAction(.init(title: "취소", style: .cancel, handler: { _ in completion(false) }))
            
            editor.present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: HEEditImageViewDelegate {
    func didClipWithoutKeepingState(_ editView: HEEditImageView, resultImage: UIImage, editId: String?) {
        //
    }
    
    
    func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditState?) {
        
    }
}

extension ViewController: HEEditorActionListener {
    func didUpdatedActions(_ actions: [HEEditAction], redoActions: [HEEditAction]) {
        editUndoBtn.isEnabled = !actions.isEmpty
        editRedoBtn.isEnabled = actions.count != redoActions.count
    }
}

extension ViewController: HEImagePickerDelegate {

    func imagePicker(_ picker: HEImagePicker, replacingItemWithIdentifer identifier: String) -> HEMediaItem? {
        let imageStore = self.imageStore
        do {
            if let hei = imageStore.getHEImage(forId: identifier) {
                let photo = try hei.toMediaPhoto(imageCache: imageStore)
                return HEMediaItem.photo(p: photo)
            }
        } catch {
            debugPrint(error)
        }
        return nil
    }
    
    func imagePicker(_ picker: HEImagePicker, captionWithIdentifer identifier: String) -> String? {
        let url = imageStore.getHEImage(forAssetIdentifier: identifier)?.editImageURL
        return url != nil ? "편집 적용" : nil
    }
    
    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem]) {
        
        picker.dismiss(animated: true) {
            Task {
                if let photo = items.singlePhoto {
//                    if let hei = picker.editImageStore.getHEImage(forId: photo.identifier) {
//                        debugPrint(photo)
//                        if let editURL = hei.editImageURL {
//                            if let data = try? Data(contentsOf: editURL) {
//                                self.resultImageView.image = UIImage(data: data)
//                            }
//                        } else if let originURL = hei.originURL {
//                            if originURL.pathExtension == "gif" {
//                                self.resultImageView.loadGif(url: originURL)
//                            } else if let data = try? Data(contentsOf: originURL) {
//                                self.resultImageView.image = UIImage(data: data)
//                            }
//                        }
//                    } else if let asset = photo.asset, asset.playbackStyle == .imageAnimated {
//                        debugPrint("GIF 원본이다!!", photo)
//                        
//                    }
                }
            }
        }
    }
    
    func imagePicker(_ picker: HEImagePicker, didCaptureItem item: HEMediaItem) {
        debugPrint(item)
    }
    
    func imagePickerDidCancel(_ picker: HEImagePicker) {
        picker.dismiss(animated: true)
    }
    
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem, inItems items: [HEMediaItem]) {
        // 편집 시작
        var news = [HEEditImage]()
        let exists = self.imageStore.all()
        items.enumerated().forEach { it in
            switch it.element {
            case .photo(let photo):
                if let exist = exists.first(where: { $0.id == photo.identifier}), // 피커의 identifier는 어셋 우선
                   let hei = HEEditImage.fromHEImage(exist) {
                    news.append(hei)
                    debugPrint("ViewController-didSelectToEditItem",hei)
                } else {
                    let hei = HEEditImage(id: photo.identifier,
                                          origin: photo.url,
                                          editState: nil,
                                          phAsset: photo.asset)
                    news.append(hei)
                    debugPrint(hei)
                }
                break
            case .video(_):
                // TODO: 동영상 처리
                break
            }
        }
        
        imageStore.clearAll()
        imageStore.addHEImages(news)
        
        let vc = HEImageEditorViewController(imageStore: imageStore, stickerDataSource: self)
        
        vc.delegate = self
        vc.initialIndex = items.firstIndex(where: { $0.identifier == item.identifier }) ?? 0
        picker.pushViewController(vc, animated: true)
    }
    
    func imagePicker(_ picker: HEImagePicker, shouldAddToSelection identifier: String, numSelections: Int) -> Bool {
        if numSelections > 0,
           let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject {
            if asset.mediaType == .video {
                let alert = UIAlertController(title: nil, message: "동영상은 1개까지 선택 가능합니다.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "확인", style: .default, handler: nil)
                alert.addAction(okayAction)
                self.findPresentaion().present(alert, animated: true, completion: nil)
                return false
            }
        }
        return true
    }
}



//
//extension ViewController: PHPickerViewControllerDelegate {
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        print(results)
//        
//        picker.dismiss(animated: true)
//        
//        
//        Task {
//            let existing: OrderedDictionary<String, HEEditImage> = imageStore.all().reduce(into: OrderedDictionary<String, HEImage>()) {
//                $0[$1.id] = $1
//            }.compactMapValues({ $0 as? HEEditImage })
//            
//            var newSelection = OrderedDictionary<String, HEEditImage>()
//            for result in results {
//                if let identifier = result.assetIdentifier {
//                    if let exist = existing[identifier] {
//                        newSelection[identifier] = exist
//                    } else {
//                        if let image = await loadImageObject(result: result) {
//                            print("image= \(image.size.width) x \(image.size.height)")
//                            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [result.assetIdentifier ?? ""], options: nil).firstObject
//                            if let fileUrl = try? await imageStore.cacheOriginImage(uiImage: image, forId: identifier, isGif: asset?.playbackStyle == .imageAnimated).value {
//                                newSelection[identifier] = HEEditImage(
//                                    id: identifier,
//                                    origin: fileUrl,
//                                    editState: nil,
//                                    phAsset: asset
//                                )
//                            } else {
//                                if let data = await HEImageUtil.checkImageDataAndResize(image: image) {
//                                    do {
//                                        let url = try await HEImageUtil.saveTempImageData(data, name: identifier.toHEImageCacheIdentifier() + ".jpg")
//                                        newSelection[identifier] = HEEditImage(
//                                            id: identifier,
//                                            origin: url,
//                                            editState: nil,
//                                            phAsset: asset
//                                        )
//                                    } catch {
//                                        debugPrint(error)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            
//            if newSelection.isEmpty { return }
//            let images = newSelection.values.map({ $0 })
//            startEditMultipleImages(images)
//        }
//        
//    }
//    
//    private func loadImageObject(result: PHPickerResult) async -> UIImage? {
//        let itemProvider = result.itemProvider
//        return await withCheckedContinuation { continuation in
//            if itemProvider.canLoadObject(ofClass: UIImage.self) {
//                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
//                    continuation.resume(with: .success(image as? UIImage))
//                }
//            } else {
//                continuation.resume(with: .success(nil))
//            }
//        }
//    }
//    
//    private func askAuthorization(granted: @escaping () -> Void) {
//        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
//            switch status {
//                
//            case .limited:
//                print("limited authorization granted")
//                
//            case .authorized:
//                print("authorization granted")
//                DispatchQueue.main.async {
//                    granted()                    
//                }
//            default:
//                print("Unimplemented")
//                
//            }
//        }
//    }
//}


extension ViewController {
    
    private func findPresentaion() -> UIViewController {
        var vc: UIViewController = self
        while true {
            if let v = vc.presentedViewController, !(v is UIAlertController) {
                vc = v
            } else {
                break
            }
        }
        return vc
    }
    
//    // MARK: Start HEImagePicker with picking a image
//    
    @objc func pickImage() {
        
        var config = HEImagePickerConfiguration()
        config.pickerSources = [.libraryPick, .photoCapture]
        config.shouldSaveNewPicturesToAlbum = true
        config.shouldSelectSingleType = false
        config.library.mediaType = .photoAndVideo
        config.library.defaultMultipleSelection = false
        config.library.maxNumberOfItems = 1
        
        let picker = HEImagePicker(configuration: config)
        picker.pickerDelegate = self
        picker.editImageStore = self.imageStore
        showDetailViewController(picker, sender: nil)
    }
//    
//    // MARK: Start HEImageEditor with picking multiple images
//    
//    @objc func pickMutipleImages() {
//        askAuthorization { [weak self] in
//            var configuration = PHPickerConfiguration(photoLibrary: .shared())
//            configuration.filter = PHPickerFilter.any(of: [.images, .livePhotos])
//            configuration.selectionLimit = 100
//            configuration.preferredAssetRepresentationMode = .current
//            if #available(iOS 17.0, *) {
//                configuration.mode = .default
//            }
//            if #available(iOS 15.0, *) {
//                configuration.selection = .ordered
//            }
//            let picker = PHPickerViewController(configuration: configuration)
//            picker.delegate = self
//            
//            self?.showDetailViewController(picker, sender: nil)
//        }
//    }
    
    // MARK: Start HEImagePicker with HEImageEditor
    
    @objc func pickWithHEPicker100() {
        
        var config = HEImagePickerConfiguration()
        config.pickerSources = [.libraryPick, .photoCapture]
        config.shouldSaveNewPicturesToAlbum = true
        config.library.mediaType = .photo
        config.library.defaultMultipleSelection = true
        config.library.maxNumberOfItems = 100
        
        let picker = HEImagePicker(configuration: config)
        picker.pickerDelegate = self
        picker.editImageStore = self.imageStore
        showDetailViewController(picker, sender: nil)
    }
    
    
    // ex
    private func makeTopToolBuilder() -> HEEditImageTopToolViewBuilder {
        return { [weak self] editView in
            let toolView = HETopBarView()
            if let self {
                toolView.addLeadingView(editCancelBtn)
                toolView.addTrailingView(editUndoBtn)
                toolView.addTrailingView(editRedoBtn)
                toolView.addTrailingView(editDoneBtn)
                
                editCancelBtn.addAction(.init(handler: { _ in
                    editView.cancel()
                }), for: .touchUpInside)
                
                editUndoBtn.addAction(.init(handler: { _ in
                    editView.undo()
                }), for: .touchUpInside)
                
                editRedoBtn.addAction(.init(handler: { _ in
                    editView.redo()
                }), for: .touchUpInside)
                
                editDoneBtn.addAction(.init(handler: { _ in
                    editView.done()
                }), for: .touchUpInside)
                
                editView.addActionChangedListener(self)
            }
            return (toolView, 44)
        }
    }
    
    // ex
    private func makeDefaultClipImageBottomToolBuilder() -> HEClipImageBottomViewBuilder {
        return { (clipView: HEClipImageView) in
            let toolView = HEClipBottomView()
            toolView.cancelClickListener = { clipView.cancelEdit() }
            toolView.doneClickListener = { clipView.doneEdit() }
            toolView.revertClickListener = { clipView.revertEdit() }
            return (toolView, HEClipBottomView.estimateHeight)
        }
    }
}

// UIImagePicker 예시
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            guard var image = info[.originalImage] as? UIImage else { return }
            let w = min(1280, image.he.width)
            image = image.he.resize(newWidth: w)
            self.startEditSingleImage(image, editState: nil)
        }
    }
}

