//
//  UIHelper.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

struct UIHelper {
    
    static var defaultLoader: UIBarButtonItem {
        let spinner = UIActivityIndicatorView(style: .medium)
        if let spinnerColor = PickerConfig.colors.navigationBarActivityIndicatorColor {
            spinner.color = spinnerColor
        } else {
            if #available(iOS 13, *) {
                let spinnerColor = UIColor { trait -> UIColor in
                    return trait.userInterfaceStyle == .dark ? .white : .gray
                }
                spinner.color = spinnerColor
            }
        }
        spinner.startAnimating()
        return UIBarButtonItem(customView: spinner)
    }
    
    static func changeBackButtonIcon(_ controller: UIViewController) {
        if PickerConfig.icons.shouldChangeDefaultBackButtonIcon {
            let backButtonIcon = PickerConfig.icons.backButtonIcon
            controller.navigationController?.navigationBar.backIndicatorImage = backButtonIcon
            controller.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonIcon
        }
    }
    
    static func changeBackButtonTitle(_ controller: UIViewController) {
        if PickerConfig.icons.hideBackButtonTitle {
            controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                                          style: .plain,
                                                                          target: nil,
                                                                          action: nil)
        }
    }
    
    static func configureFocusView(_ v: UIView) {
        v.alpha = 0.0
        v.backgroundColor = UIColor.clear
        v.layer.borderColor = UIColor.ypSecondaryLabel.cgColor
        v.layer.borderWidth = 1.0
        v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    }
    
    static func animateFocusView(_ v: UIView) {
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0, options: UIView.AnimationOptions.curveEaseIn,
                       animations: {
                        v.alpha = 1.0
                        v.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            v.removeFromSuperview()
        })
    }
    
    static func formattedStrigFrom(_ timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    static func videoTooLongAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: PickerConfig.wordings.videoDurationPopup.tooLongMessage,
                         "\(PickerConfig.video.libraryTimeLimit)")
        let alert = UIAlertController(title: PickerConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
                                                  y: sourceView.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: PickerConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert(_ sourceView: UIView) -> UIAlertController {
        let msg = String(format: PickerConfig.wordings.videoDurationPopup.tooShortMessage,
                         "\(PickerConfig.video.minimumTimeLimit)")
        let alert = UIAlertController(title: PickerConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
                                                  y: sourceView.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }
        alert.addAction(UIAlertAction(title: PickerConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
}
