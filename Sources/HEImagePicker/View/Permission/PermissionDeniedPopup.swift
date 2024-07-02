//
//  YPPermissionDeniedPopup.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

internal struct PermissionDeniedPopup {
    static func buildGoToSettingsAlert(cancelBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: PickerConfig.wordings.permissionPopup.title,
                                      message: PickerConfig.wordings.permissionPopup.message,
                                      preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.permissionPopup.cancel,
                          style: UIAlertAction.Style.cancel,
                          handler: { _ in
                            cancelBlock()
                          }))
        alert.addAction(
            UIAlertAction(title: PickerConfig.wordings.permissionPopup.grantPermission,
                          style: .default,
                          handler: { _ in
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                            } else {
                                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                            }
                          }))
        return alert
    }
}
