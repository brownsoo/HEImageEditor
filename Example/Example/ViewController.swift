//
//  ViewController.swift
//  Example
//
//  Created by long on 2020/11/23.
//

import UIKit
import SnapKit
import HEImageEditor

class ViewController: UIViewController {
    var editImageToolView: UIView!
    
    var editImageDrawToolSwitch: UISwitch!
    
    var editImageClipToolSwitch: UISwitch!
    
    var editImageImageStickerToolSwitch: UISwitch!
    
    var editImageTextStickerToolSwitch: UISwitch!
    
    var editImageMosaicToolSwitch: UISwitch!
    
    var editImageFilterToolSwitch: UISwitch!
    
    var editImageAdjustToolSwitch: UISwitch!
    
    var pickImageBtn: UIButton!
    
    var resultImageView: UIImageView!
    
    var originalImage: UIImage?
    
    var resultImageEditModel: HEEditImageModel?
    
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
    }
    
    
    var imageStickers: [HEImageSticker] = []
    
    func configImageEditor() {
        
        let stickerTray = HEImageStickerTrayView()
        stickerTray.dataSource = self
        
        imageStickers.append(HEImageSticker.faceAiIcon)
        imageStickers.append(HEImageSticker.mosaicIcon)
        imageStickers.append(contentsOf: (1...18).map { (v) -> String in
            "imageSticker" + String(v)
        }.compactMap {
            HEImageSticker(id: $0, image: UIImage(named: $0) ?? UIImage())
        })
        
        HEConfiguration.default()
            .clipRatios([.origin, .custom, .wh1x1])
            .imageStickerTray(stickerTray)
    }
    
    
}

extension ViewController: HEImageStickerTrayViewDataSource {
    
    func hasMosaicSticker(_ trayView: HEImageStickerTrayView) -> Bool {
        true
    }
    
    func imageStickerTrayView(_ trayView: HEImageEditor.HEImageStickerTrayView, numberOfItemsInSection section: Int) -> Int {
        imageStickers.count
    }
    
    func imageStickerTrayView(_ trayView: HEImageEditor.HEImageStickerTrayView, stickerForItemAt indexPath: IndexPath) -> HEImageSticker {
        imageStickers[indexPath.row]
    }
    
    func allStickers(_ trayView: HEImageStickerTrayView, numberOfItemsInSection section: Int) -> [HEImageSticker] {
        return imageStickers
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
        
        startEditSingleImage(oi, editModel: resultImageEditModel)
    }
    
    func startEditSingleImage(_ image: UIImage, editModel: HEEditImageModel?) {
        HEEditImageViewController.showImageEditor(
            parent: self,
            image: image,
            editModel: editModel,
            delegate: self,
            topToolViewBuilder: makeTopToolBuilder()
        )
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

extension ViewController: HEEditImageViewControllerDelegate {
    func didFinishEditImage(resultImage: UIImage, editId: String?, editModel: HEImageEditor.HEEditImageModel?) {
        self.resultImageView.image = resultImage
        self.resultImageEditModel = editModel
    }
}

extension ViewController: HEEditorActionListener {
    func didUpdatedActions(_ actions: [HEEditorAction], redoActions: [HEEditorAction]) {
        editUndoBtn.isEnabled = !actions.isEmpty
        editRedoBtn.isEnabled = actions.count != redoActions.count
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
            self.startEditSingleImage(image, editModel: nil)
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
        
        pickImageBtn = UIButton(type: .custom)
        pickImageBtn.backgroundColor = .black
        pickImageBtn.layer.cornerRadius = 5
        pickImageBtn.layer.masksToBounds = true
        pickImageBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        pickImageBtn.setTitle("Pick an image", for: .normal)
        pickImageBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        view.addSubview(pickImageBtn)
        pickImageBtn.snp.makeConstraints { make in
            make.top.equalTo(self.editImageToolView.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }
        
        resultImageView = UIImageView()
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.clipsToBounds = true
        resultImageView.backgroundColor = .systemGray
        view.addSubview(resultImageView)
        resultImageView.snp.makeConstraints { make in
            make.top.equalTo(self.pickImageBtn.snp.bottom).offset(spacing)
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
