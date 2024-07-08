//
//  ViewController.swift
//  Example
//
//  Created by long on 2020/11/23.
//  Changed by brownsoo on 2024/summer

import UIKit
import SnapKit
import HECommon
import HEImageEditor
import HEImagePicker
import PhotosUI
import OrderedCollections

class ViewController: UIViewController {
    var editImageToolView: UIView!
    var editImageDrawToolSwitch: UISwitch!
    var editImageClipToolSwitch: UISwitch!
    var editImageImageStickerToolSwitch: UISwitch!
    var editImageTextStickerToolSwitch: UISwitch!
    var editImageMosaicToolSwitch: UISwitch!
    var editImageFilterToolSwitch: UISwitch!
    var editImageAdjustToolSwitch: UISwitch!
    var resultImageView: UIImageView!
    var originalImage: UIImage?
    var resultImageEditState: HEEditState?
    let config = HEConfiguration.default()
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configImageEditor()
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
                
            case .limited:
                print("limited authorization granted")
                
            case .authorized:
                print("authorization granted")
                
            default:
                print("Unimplemented")
                
            }
        }
    }
    
    
    var imageStickers: [HEImageSticker] = []
    
    lazy var imageStore = HESimpleImageStore()
    
    
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
        
        HEConfiguration.default()
            .clipRatios([.origin, .custom, .wh1x1])
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
                                            imageCache: imageStore,
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
    func didFinishEditImages(_ editor: HEImageEditor) {
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
    func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditState?) {
        self.resultImageView.image = resultImage
        self.resultImageEditState = editModel
    }
}

extension ViewController: HEEditorActionListener {
    func didUpdatedActions(_ actions: [HEEditAction], redoActions: [HEEditAction]) {
        editUndoBtn.isEnabled = !actions.isEmpty
        editRedoBtn.isEnabled = actions.count != redoActions.count
    }
}


extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print(results)
        
        picker.dismiss(animated: true)
        
        
        Task {
            let existing: OrderedDictionary<String, HEEditImage> = imageStore.all().reduce(into: OrderedDictionary<String, HEImage>()) {
                $0[$1.id] = $1
            }.compactMapValues({ $0 as? HEEditImage })
            
            var newSelection = OrderedDictionary<String, HEEditImage>()
            for result in results {
                if let identifier = result.assetIdentifier?.replacingOccurrences(of: "/", with: "~") {
                    if let exist = existing[identifier] {
                        newSelection[identifier] = exist
                    } else {
                        if let image = await loadImageObject(result: result) {
                            print("image= \(image.size.width) x \(image.size.height)")
                            if let fileUrl = try? await imageStore.cacheOriginImage(uiImage: image, forId: identifier).value {
                                newSelection[identifier] = HEEditImage(
                                    id: identifier,
                                    origin: fileUrl,
                                    editState: nil
                                )
                            } else {
                                newSelection[identifier] = HEEditImage(
                                    id: identifier,
                                    image: image,
                                    editState: nil
                                )
                            }
                        }
                    }
                }
            }
            
            if newSelection.isEmpty { return }
            let images = newSelection.values.map({ $0 })
            startEditMultipleImages(images)
        }
        
    }
    
    private func loadImageObject(result: PHPickerResult) async -> UIImage? {
        let itemProvider = result.itemProvider
        return await withCheckedContinuation { continuation in
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    continuation.resume(with: .success(image as? UIImage))
                }
            } else {
                continuation.resume(with: .success(nil))
            }
        }
    }
    
}

extension ViewController: HEImagePickerDelegate {
    func imagePicker(_ picker: HEImagePicker, replacingItemAt indexPath: IndexPath) -> HEMediaItem? {
        nil
    }
    
    func imagePicker(_ picker: HEImagePicker, captionAt indexPath: IndexPath) -> String? {
        "하이"
    }
    
    func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem]) {
        print(items)
    }
    
    func imagePickerDidCancel(_ picker: HEImagePicker) {
        picker.dismiss(animated: true)
    }
    
    func imagePicker(_ picker: HEImagePicker, didSelectToEditItem item: HEMediaItem) {
        
    }
}


extension ViewController {
    
    @objc func pickImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        showDetailViewController(picker, sender: nil)
    }
    
    @objc func pickMutipleImages() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.any(of: [.images, .livePhotos])
        configuration.selectionLimit = 100
        configuration.preferredAssetRepresentationMode = .current
        if #available(iOS 17.0, *) {
            configuration.mode = .default
        }
        if #available(iOS 15.0, *) {
            configuration.selection = .ordered
            // TODO: configuration.preselectedAssetIdentifiers
        }
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        showDetailViewController(picker, sender: nil)
    }
    
    // MARK: Start HEImagePicker
    @objc func pickWithHEPicker() {
        
        var config = HEImagePickerConfiguration()
        config.pickerSources = [.libraryPick, .photoCapture, .videoCapture]
        config.shouldSaveNewPicturesToAlbum = false
        config.library.defaultMultipleSelection = true
        config.library.maxNumberOfItems = 100
        
        let picker = HEImagePicker(configuration: config)
        picker.pickerDelegate = self
        showDetailViewController(picker, sender: nil)
//        present(picker, animated: true)
    }
    
    @objc func drawToolChanged() {
        if config.tools.contains(.draw) {
            config.tools.removeAll { $0 == .draw }
        } else {
            config.tools.append(.draw)
        }
    }
    
    @objc func clipToolChanged() {
        if config.tools.contains(.clip) {
            config.tools.removeAll { $0 == .clip }
        } else {
            config.tools.append(.clip)
        }
    }
    
    @objc func imageStickerToolChanged() {
        if config.tools.contains(.imageSticker) {
            config.tools.removeAll { $0 == .imageSticker }
        } else {
            config.tools.append(.imageSticker)
        }
    }
    
    @objc func textStickerToolChanged() {
        if config.tools.contains(.textSticker) {
            config.tools.removeAll { $0 == .textSticker }
        } else {
            config.tools.append(.textSticker)
        }
    }
    
    @objc func mosaicToolChanged() {
        if config.tools.contains(.mosaicDraw) {
            config.tools.removeAll { $0 == .mosaicDraw }
        } else {
            config.tools.append(.mosaicDraw)
        }
    }
    
    @objc func filterToolChanged() {
        if config.tools.contains(.filter) {
            config.tools.removeAll { $0 == .filter }
        } else {
            config.tools.append(.filter)
        }
    }
    
    @objc func adjustToolChanged() {
        if config.tools.contains(.adjust) {
            config.tools.removeAll { $0 == .adjust }
        } else {
            config.tools.append(.adjust)
        }
    }
    
    @objc func continueEditImage() {
        guard let oi = originalImage else {
            return
        }
        
        startEditSingleImage(oi, editState: resultImageEditState)
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

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            guard var image = info[.originalImage] as? UIImage else { return }
            let w = min(1500, image.he.width)
            let h = w * image.he.height / image.he.width
            image = image.he.resize(CGSize(width: w, height: h)) ?? image
            self.originalImage = image
            self.startEditSingleImage(image, editState: nil)
        }
    }
}


extension ViewController {
    func setupUI() {
        title = "Main"
        view.backgroundColor = .white
        
        func createLabel(_ title: String) -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .black
            label.text = title
            return label
        }
        
        let spacing: CGFloat = 20
        // Container
        editImageToolView = UIView()
        view.addSubview(editImageToolView)
        editImageToolView.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin).offset(5)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }
        
        let drawToolLabel = createLabel("Draw")
        editImageToolView.addSubview(drawToolLabel)
        drawToolLabel.snp.makeConstraints { make in
            make.top.equalTo(self.editImageToolView).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageDrawToolSwitch = UISwitch()
        editImageDrawToolSwitch.isOn = config.tools.contains(.draw)
        editImageDrawToolSwitch.addTarget(self, action: #selector(drawToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageDrawToolSwitch)
        editImageDrawToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(drawToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(drawToolLabel)
        }
        
        let cropToolLabel = createLabel("Crop")
        editImageToolView.addSubview(cropToolLabel)
        cropToolLabel.snp.makeConstraints { make in
            make.centerY.equalTo(drawToolLabel)
            make.left.equalTo(self.editImageToolView.snp.centerX)
        }
        
        editImageClipToolSwitch = UISwitch()
        editImageClipToolSwitch.isOn = config.tools.contains(.clip)
        editImageClipToolSwitch.addTarget(self, action: #selector(clipToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageClipToolSwitch)
        editImageClipToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(cropToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(cropToolLabel)
        }
        
        let imageStickerToolLabel = createLabel("Image sticker")
        editImageToolView.addSubview(imageStickerToolLabel)
        imageStickerToolLabel.snp.makeConstraints { make in
            make.top.equalTo(drawToolLabel.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageImageStickerToolSwitch = UISwitch()
        editImageImageStickerToolSwitch.isOn = config.tools.contains(.imageSticker)
        editImageImageStickerToolSwitch.addTarget(self, action: #selector(imageStickerToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageImageStickerToolSwitch)
        editImageImageStickerToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(imageStickerToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(imageStickerToolLabel)
        }
        
        let textStickerToolLabel = createLabel("Text sticker")
        editImageToolView.addSubview(textStickerToolLabel)
        textStickerToolLabel.snp.makeConstraints { make in
            make.centerY.equalTo(imageStickerToolLabel)
            make.left.equalTo(self.editImageToolView.snp.centerX)
        }
        
        editImageTextStickerToolSwitch = UISwitch()
        editImageTextStickerToolSwitch.isOn = config.tools.contains(.textSticker)
        editImageTextStickerToolSwitch.addTarget(self, action: #selector(textStickerToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageTextStickerToolSwitch)
        editImageTextStickerToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(textStickerToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(textStickerToolLabel)
        }
        
        let mosaicToolLabel = createLabel("Mosaic Draw")
        editImageToolView.addSubview(mosaicToolLabel)
        mosaicToolLabel.snp.makeConstraints { make in
            make.top.equalTo(imageStickerToolLabel.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageMosaicToolSwitch = UISwitch()
        editImageMosaicToolSwitch.isOn = config.tools.contains(.mosaicDraw)
        editImageMosaicToolSwitch.addTarget(self, action: #selector(mosaicToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageMosaicToolSwitch)
        editImageMosaicToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(mosaicToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(mosaicToolLabel)
        }
        
        let filterToolLabel = createLabel("Filter")
        editImageToolView.addSubview(filterToolLabel)
        filterToolLabel.snp.makeConstraints { make in
            make.centerY.equalTo(mosaicToolLabel)
            make.left.equalTo(self.editImageToolView.snp.centerX)
        }
        
        editImageFilterToolSwitch = UISwitch()
        editImageFilterToolSwitch.isOn = config.tools.contains(.filter)
        editImageFilterToolSwitch.addTarget(self, action: #selector(filterToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageFilterToolSwitch)
        editImageFilterToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(filterToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(filterToolLabel)
        }
        
        let adjustToolLabel = createLabel("Adjust")
        editImageToolView.addSubview(adjustToolLabel)
        adjustToolLabel.snp.makeConstraints { make in
            make.top.equalTo(mosaicToolLabel.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        editImageAdjustToolSwitch = UISwitch()
        editImageAdjustToolSwitch.isOn = config.tools.contains(.adjust)
        editImageAdjustToolSwitch.addTarget(self, action: #selector(adjustToolChanged), for: .valueChanged)
        editImageToolView.addSubview(editImageAdjustToolSwitch)
        editImageAdjustToolSwitch.snp.makeConstraints { make in
            make.left.equalTo(adjustToolLabel.snp.right).offset(spacing)
            make.centerY.equalTo(adjustToolLabel)
            make.bottom.equalTo(self.editImageToolView)
        }
        
        let pickImageBtn = UIButton(type: .system)
        pickImageBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        pickImageBtn.setTitle("UIImagePicker", for: .normal)
        pickImageBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        view.addSubview(pickImageBtn)
        pickImageBtn.snp.makeConstraints { make in
            make.top.equalTo(self.editImageToolView.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        let pickMultipleBt = UIButton(type: .system)
        pickMultipleBt.setTitle("PHPicker", for: .normal)
        pickMultipleBt.addTarget(self, action: #selector(pickMutipleImages), for: .touchUpInside)
        view.addSubview(pickMultipleBt)
        pickMultipleBt.snp.makeConstraints { make in
            make.top.equalTo(pickImageBtn)
            make.left.equalTo(pickImageBtn.snp.right).offset(20)
        }
        
        let hePickerBt = UIButton(type: .system)
        hePickerBt.setTitle("HEPicker", for: .normal)
        hePickerBt.addTarget(self, action: #selector(pickWithHEPicker), for: .touchUpInside)
        view.addSubview(hePickerBt)
        hePickerBt.snp.makeConstraints { make in
            make.top.equalTo(pickMultipleBt)
            make.left.equalTo(pickMultipleBt.snp.right).offset(20)
        }
        
        resultImageView = UIImageView()
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.clipsToBounds = true
        resultImageView.backgroundColor = .systemGray
        view.addSubview(resultImageView)
        resultImageView.snp.makeConstraints { make in
            make.top.equalTo(pickImageBtn.snp.bottom).offset(spacing)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottomMargin)
        }
        
        let control = UIControl()
        control.addTarget(self, action: #selector(continueEditImage), for: .touchUpInside)
        view.addSubview(control)
        control.snp.makeConstraints { make in
            make.edges.equalTo(self.resultImageView)
        }
    }
    
}
