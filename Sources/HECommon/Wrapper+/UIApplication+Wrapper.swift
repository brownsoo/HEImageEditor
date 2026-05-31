//
//  UIApplication+Wrapper.swift
//  HECommon
//
//  Created by 브라운수 on 7/8/24.
//

import UIKit

public extension HEWrapper where Base: UIApplication {
    
    @available(iOS 13.0, *)
    func findWindowScenes() -> [UIWindowScene] {
        return UIApplication.shared.connectedScenes
            .sorted {
                $0.activationState.sortPriority < $1.activationState.sortPriority
            }
            .compactMap({ $0 as? UIWindowScene })
    }
    
    func findKeyWindow() -> UIWindow? {
        let scenes = findWindowScenes()
        if #available(iOS 15, *) {
            return scenes.first(where: { $0.keyWindow != nil })?.keyWindow ?? scenes.first?.keyWindow
        } else {
            return scenes.compactMap {
                $0.windows.first { $0.isKeyWindow }
            }
            .first
        }
    }
    
    func findKeyRootViewController() -> UIViewController? {
        return findKeyWindow()?.rootViewController
    }
}

@available(iOS 13.0, *)
private extension UIScene.ActivationState {
    var sortPriority: Int {
        switch self {
        case .foregroundActive: return 1
        case .foregroundInactive: return 2
        case .background: return 3
        case .unattached: return 4
        @unknown default: return 5
        }
    }
}
