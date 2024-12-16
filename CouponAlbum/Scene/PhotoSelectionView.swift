//
//  PhotoSelectionView.swift
//  CouponAlbum
//
//  Created by 브라운수 on 12/16/24.
//

import SwiftUI
import HECommon
import HEImagePicker
import HEImageEditor

struct PhotoSelectionView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    var didSelectedImage: (([URL]) -> Void)
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var config = HEImagePickerConfiguration()
        config.pickerSources = [.libraryPick, .photoCapture]
        config.shouldSaveNewPicturesToAlbum = true
        config.shouldSelectSingleType = false
        config.library.mediaType = .photo
        config.library.defaultMultipleSelection = true
        config.library.maxNumberOfItems = 100

        let vc = CouponImagePicker(configuration: config)
        vc.pickerDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let vc = uiViewController as? CouponImagePicker else {
            return
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coord = Coordinator(view: self)
        return coord
    }
 
    class Coordinator: NSObject, HEImagePickerDelegate {
        
        var view: PhotoSelectionView
        
        init(view: PhotoSelectionView) {
            self.view = view
        }
        
        func imagePicker(_ picker: HEImagePicker, didSelectItems items: [HEMediaItem]) {
            switch items.first {
            case .photo(let photo):
                view.didSelectedImage(items.photoItems.map { $0.url })
                
            case .video(_):
                break
                
            case .none:
                break
            }
        }
        
        func imagePickerDidCancel(_ picker: HEImagePicker) {
            view.isPresented = false
        }
    }
}


final class CouponImagePicker: HEImagePicker {
    var imageStickers: [HEImageSticker] = []
    lazy var imageStore = HESimpleEditImageStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.editImageStore = self.imageStore
    }
}

//@objc func pickImage() {
//    
//    var config = HEImagePickerConfiguration()
//    config.pickerSources = [.libraryPick, .photoCapture]
//    config.shouldSaveNewPicturesToAlbum = true
//    config.shouldSelectSingleType = false
//    config.library.mediaType = .photoAndVideo
//    config.library.defaultMultipleSelection = false
//    config.library.maxNumberOfItems = 1
//    
//    let picker = HEImagePicker(configuration: config)
//    picker.pickerDelegate = self
//    picker.editImageStore = self.imageStore
//    showDetailViewController(picker, sender: nil)
//}
