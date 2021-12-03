//
//  AppDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import SwiftUI
import Kingfisher
import SwiftTrace

var globalLaunchCoordinator: LaunchCoordinator? {
    if #available(iOS 13.0, *) {
        return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.launch
    } else {
        return (UIApplication.shared.delegate as? AppDelegate)?.launch
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var launch: LaunchCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 10
        WXApi.registerApp(Env().wechatAppId, universalLink: Env().baseURL)
        if #available(iOS 13, *) {
            // SceneDelegate
        } else {
            let url = launchOptions?[.url] as? URL
            window = UIWindow(frame: UIScreen.main.bounds)
            launch = LaunchCoordinator(window: window!, authStore: AuthStore.shared, defaultLaunchItems: [JoinRoomLaunchItem()])
            launch?.start(withLaunchUrl: url)
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        launch?.start(withLaunchUrl: url)
        return true
    }
    

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let _ = launch?.start(withLaunchUserActivity: userActivity)
        return true
    }
}

