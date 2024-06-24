//
//  TakePhoto.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/24/24.
//

import UIKit
import Foundation
import AVFoundation
import Photos

protocol TakePhotoError: Error {
}
struct TakePhotoUndefinedError: TakePhotoError {
    public var localizedDescription: String {
        return "Can't take a photo"
    }
}

protocol TakePhoto: UINavigationControllerDelegate & UIImagePickerControllerDelegate {
    
    var picker: UIImagePickerController { get }
    func tryTakePhoto(type: UIImagePickerController.SourceType, allowEditing edit: Bool)
    func imageTaken(url: URL?, image: UIImage?, fileName: String, info: [UIImagePickerController.InfoKey: Any]) -> Void
    func imageTakenError(_ error: Error)
    func imageTakenGenerateName() -> String
}

extension TakePhoto where Self : UIViewController {
    
    
    func imageTakenGenerateName() -> String {
        return "temp_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
    }
    
    func imageTakenError(_ error: Error) {
        debugPrint(error)
    }
    
    func tryTakePhoto(type: UIImagePickerController.SourceType, allowEditing edit: Bool) {
        let successCallback = { [weak self] in
            guard let this = self else { return }
            this.picker.delegate = self
            this.picker.sourceType = type
            this.picker.allowsEditing = edit
            this.present(this.picker, animated: true)
        }
        if type == .camera {
            checkCapturePermission(successCallback)
        } else {
            checkPhotoLibraryPermission(successCallback)
        }
    }
    
    
    // result
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let fileName: String
        let url = info[.imageURL] as? URL
        if let asset = info[.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            fileName = assetResources.first!.originalFilename
        } else {
            if let imageUrl = url {
                fileName = imageUrl.lastPathComponent
            } else {
                fileName = imageTakenGenerateName()
            }
        }
        
        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        
        if url != nil {
            // 어디에서 가져온 경우
            self.imageTaken(url: url, image: img, fileName: fileName, info: info)
        } else {
            // 촬영한 경우
            if img != nil {
                HEImageUtil.saveTempImageUsingJpeg(img!, name: fileName) { [weak self] (url, e) in
                    guard let this = self else { return }
                    if url != nil {
                        this.imageTaken(url: url, image: img, fileName: fileName, info: info)
                    } else {
                        if let error = e {
                            this.imageTakenError(error)
                        } else {
                            this.imageTakenError(TakePhotoUndefinedError())
                        }
                    }
                }
            }
        }
    }
    
    func checkPhotoLibraryPermission(_ success: @escaping () -> Void) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
            case .authorized:
                success()
            case .denied:
                let alert = UIAlertController(title: nil,
                                              message: "perms_accessing_album".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "go_to_setting".localized(), style: .default, handler: { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "cancel".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
            case .restricted, .limited:
                let alert = UIAlertController(title: nil,
                                              message: "perms_limited_album".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            success()
                        }
                    } else {
                        let alert = UIAlertController(title: nil,
                                                      message: "perms_limited_album".localized(),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
                
            @unknown default:
                let alert = UIAlertController(title: nil,
                                              message: "Can't handle unknown status: \(status)",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
        }
    }
    
    func checkCapturePermission(_ success: @escaping ()-> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
            case .authorized:
                success()
            case .denied:
                let alert = UIAlertController(title: nil,
                                              message: "perms_accessing_camera".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "go_to_setting".localized(), style: .default, handler: { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "cancel".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
                
            case .restricted:
                let alert = UIAlertController(title: nil,
                                              message: "perms_limited_camera".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                    if granted {
                        DispatchQueue.main.async {
                            success()
                        }
                    } else {
                        let alert = UIAlertController(title: nil,
                                                      message: "perms_limited_camera".localized(),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                })
                
            @unknown default:
                let alert = UIAlertController(title: nil,
                                              message: "Can't handle unknown status: \(status)",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "close".localized(), style: .cancel, handler: nil))
                present(alert, animated: true)
        }
    }
    
}
