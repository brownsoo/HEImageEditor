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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let host = UIHostingController(rootView: RootView())
        self.window?.rootViewController = host
        self.window?.makeKeyAndVisible()
        return true
    }

}

