//
//  AppDelegate.swift
//  HEImageEditorDemo
//
//  HEImageEditor / HEImagePicker 라이브러리를 시뮬레이터에서
//  직접 확인하기 위한 간단한 데모 앱입니다.
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: DemoViewController())
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
