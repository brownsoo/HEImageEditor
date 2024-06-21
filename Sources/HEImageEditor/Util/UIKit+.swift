//
//  UIKit+.swift
//  HEImageEditor
//
//  Created by 브라운수 on 6/5/24.
//

import UIKit

func deviceIsiPhone() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

func deviceIsiPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    insets = UIApplication.shared.findKeyWindow()?.safeAreaInsets ?? .zero
    return insets
}


extension UIViewController {
    @discardableResult
    func showAlert(_ text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return self.showAlert(title: nil, text: text, confirmAction: confirmAction)
    }
    
    @discardableResult
    func showAlert(title: String? = nil, text: String, confirmAction: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        DispatchQueue.main.async {
            let okayAction = UIAlertAction(title: "확인", style: .default, handler: confirmAction)
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
        return alert
    }
}

extension UIEdgeInsets {
    var width: CGFloat {
        self.left + self.right
    }
    var height: CGFloat {
        self.top + self.bottom
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

extension UIApplication {
    @available(iOS 13.0, *)
    func findWindowScenes() -> [UIWindowScene] {
        return Self.shared.connectedScenes
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
