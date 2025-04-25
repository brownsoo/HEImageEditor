//
//  YPPermissionDeniedPopup.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

internal struct PermissionDeniedPopup {
    static func buildGoToSettingsAlertForCamera(cancelBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: PickerConfig.wordings.cameraPermissionPopup.title,
            message: PickerConfig.wordings.cameraPermissionPopup.messageAccess,
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.cameraPermissionPopup.cancel,
                          style: UIAlertAction.Style.cancel,
                          handler: { _ in
                              cancelBlock()
                          }))
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.cameraPermissionPopup.grantPermission,
                          style: .default,
                          handler: { _ in
                              UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                          }))
        return alert
    }
    
    static func buildGoToSettingsAlertForLibrary(cancelBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: PickerConfig.wordings.libraryPermissionPopup.title,
            message: PickerConfig.wordings.libraryPermissionPopup.messageAccess,
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.libraryPermissionPopup.cancel,
                          style: UIAlertAction.Style.cancel,
                          handler: { _ in
                              cancelBlock()
                          }))
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.libraryPermissionPopup.grantPermission,
                          style: .default,
                          handler: { _ in
                              UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                          }))
        return alert
    }
}
