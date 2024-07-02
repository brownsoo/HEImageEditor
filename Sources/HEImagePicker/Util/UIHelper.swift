//
//  UIHelper.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import UIKit

struct UIHelper {
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
}
