//
//  AppDelegate.swift
//  Example
//
//  Created by long on 2020/11/23.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var mainScreenBounds: CGRect = CGRect(origin: .zero, size: CGSize(width: 393, height: 852))
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        Self.mainScreenBounds = UIScreen.main.bounds
        
        let host = UIHostingController(rootView: RootView())
        self.window?.rootViewController = host
        self.window?.makeKeyAndVisible()
        return true
    }

}

