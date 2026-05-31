import SwiftUI
import UIKit
import HECommon
import HEImageEditor

struct PhotoSelectionView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> PickerAndEditorCoordinatorController {
        let controller = PickerAndEditorCoordinatorController(
            sourceType: sourceType,
            onComplete: onComplete,
            onCancel: onCancel
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PickerAndEditorCoordinatorController, context: Context) {}
}

final class PickerAndEditorCoordinatorController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HEEditImageViewDelegate, HEEditorActionListener {
    
    let sourceType: UIImagePickerController.SourceType
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    private var didShowPicker = false
    
    private lazy var editCancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let icon = UIImage(systemName: "chevron.backward")?.withTintColor(.white)
        btn.setImage(icon, for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private lazy var editDoneBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("완료", for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private lazy var editUndoBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setImage(UIImage(systemName: "arrow.uturn.backward.circle"), for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    private lazy var editRedoBtn: HEEnlargeButton = {
        let btn = HEEnlargeButton(type: .custom)
        btn.setImage(UIImage(systemName: "arrow.uturn.forward.circle"), for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return btn
    }()
    
    init(sourceType: UIImagePickerController.SourceType, onComplete: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.sourceType = sourceType
        self.onComplete = onComplete
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !didShowPicker else { return }
        didShowPicker = true
        
        presentPicker()
    }
    
    private func presentPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            guard let image = info[.originalImage] as? UIImage else {
                self.onCancel()
                return
            }
            
            // Fix orientation and resize image for editor performance
            let fixedImage = image.he.fixOrientation()
            let w = min(1280, fixedImage.size.width)
            let resizedImage = fixedImage.he.resize(newWidth: w)
            
            // Limit tools to clip (crop & rotate)
            HEImageEditorConfiguration.default().tools = [.clip]
            HEImageEditorConfiguration.default().clipRatios = [.origin, .custom, .wh1x1, .wh4x3]
            
            HEEditImageViewController.showImageEditor(
                parent: self,
                image: resizedImage,
                delegate: self,
                topToolViewBuilder: self.makeTopToolBuilder()
            )
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
    
    // MARK: - HEEditImageViewDelegate
    
    func didFinishEditImage(_ editView: HEEditImageView, resultImage: UIImage, editId: String?, editModel: HEEditState?) {
        // HEEditImageViewController dismisses itself on a 0.5s delay inside callback(delay: 0.5).
        // Delay onComplete to avoid sheet presentation collision and blank screens.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.onComplete(resultImage)
        }
    }
    
    func didClipWithoutKeepingState(_ editView: HEEditImageView, resultImage: UIImage, editId: String?) {}
    
    func cancelledEditImage(_ editView: HEEditImageView) {
        onCancel()
    }
    
    // MARK: - HEEditorActionListener
    
    func didUpdatedActions(_ actions: [HEEditAction], redoActions: [HEEditAction]) {
        editUndoBtn.isEnabled = !actions.isEmpty
        editRedoBtn.isEnabled = actions.count != redoActions.count
    }
    
    // MARK: - Top Tool Bar Builder
    
    private func makeTopToolBuilder() -> HEEditImageTopToolViewBuilder {
        return { [weak self] editView in
            let toolView = HETopBarView()
            if let self = self {
                toolView.addLeadingView(self.editCancelBtn)
                toolView.addTrailingView(self.editUndoBtn)
                toolView.addTrailingView(self.editRedoBtn)
                toolView.addTrailingView(self.editDoneBtn)
                
                self.editCancelBtn.addAction(.init(handler: { _ in
                    editView.cancel()
                }), for: .touchUpInside)
                
                self.editUndoBtn.addAction(.init(handler: { _ in
                    editView.undo()
                }), for: .touchUpInside)
                
                self.editRedoBtn.addAction(.init(handler: { _ in
                    editView.redo()
                }), for: .touchUpInside)
                
                self.editDoneBtn.addAction(.init(handler: { _ in
                    editView.done()
                }), for: .touchUpInside)
                
                editView.addActionChangedListener(self)
            }
            return (toolView, 44)
        }
    }
}
