//
//  PermissionCheckable.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Photos
import UIKit

internal protocol PermissionCheckable {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void)
    func doAfterCameraPermissionCheck(block: @escaping () -> Void)
    func checkLibraryPermission()
    func checkCameraPermission()
}

internal extension PermissionCheckable where Self: UIViewController {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void) {
        PermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                trace("Not enough permissions.")
            }
        }
    }

    func doAfterCameraPermissionCheck(block: @escaping () -> Void) {
        PermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                trace("Not enough permissions.")
            }
        }
    }

    func checkLibraryPermission() {
        PermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
    
    func checkCameraPermission() {
        PermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
}

struct PermissionManager {
   typealias PermissionManagerCompletion = (_ hasPermission: Bool) -> Void

   static func checkLibraryPermissionAndAskIfNeeded(sourceVC: UIViewController,
                                                    completion: @escaping PermissionManagerCompletion) {
       var status: PHAuthorizationStatus

       if #available(iOS 14, *) {
           status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
       } else {
           status = PHPhotoLibrary.authorizationStatus()
       }

       switch status {
       case .authorized:
           completion(true)
       case .limited:
           completion(true)
       case .restricted, .denied:
           let alert = PermissionDeniedPopup.buildGoToSettingsAlertForLibrary(cancelBlock: {
               completion(false)
           })
           sourceVC.present(alert, animated: true, completion: nil)
       case .notDetermined:
           // Show permission popup and get new status
           if #available(iOS 14, *) {
               PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                   DispatchQueue.main.async {
                       completion(s == .authorized || s == .limited)
                   }
               }
           } else {
               PHPhotoLibrary.requestAuthorization { s in
                   DispatchQueue.main.async {
                       completion(s == .authorized)
                   }
               }
           }
       @unknown default:
           trace("Bug. Write to developers please.")
       }
   }

   static func checkCameraPermissionAndAskIfNeeded(sourceVC: UIViewController,
                                                   completion: @escaping PermissionManagerCompletion) {
       let type: AVMediaType = .video
       let status = AVCaptureDevice.authorizationStatus(for: type)

       switch status {
       case .authorized:
           completion(true)
       case .restricted, .denied:
           let alert = PermissionDeniedPopup.buildGoToSettingsAlertForCamera(cancelBlock: {
               completion(false)
           })
           sourceVC.present(alert, animated: true, completion: nil)
       case .notDetermined:
           AVCaptureDevice.requestAccess(for: type) { granted in
               DispatchQueue.main.async {
                   completion(granted)
               }
           }
       @unknown default:
           trace("Bug. Write to developers please.")
       }
   }
}
