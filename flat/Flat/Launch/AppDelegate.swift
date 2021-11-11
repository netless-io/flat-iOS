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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var launch: LaunchCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let new: User = .init(name: "xys_github", avatar: .init(string: "https://avatars.githubusercontent.com/u/67670791?v=4")!, userUUID: "9dec6d84-ca9a-4333-9cf6-a19734768e3a", token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6IjlkZWM2ZDg0LWNhOWEtNDMzMy05Y2Y2LWExOTczNDc2OGUzYSIsImxvZ2luU291cmNlIjoiR2l0aHViIiwiaWF0IjoxNjM1MzkxNjgxLCJleHAiOjE2Mzc4OTcyODEsImlzcyI6ImZsYXQtc2VydmVyIn0.4ynjtc5GqjRsqVcmA-WkTv7FK9ArwiVSqhhLyU7xMm0")
        AuthStore.shared.processNewUser(new)
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 10
        if #available(iOS 13, *) {
            // SceneDelegate
        } else {
            let url = launchOptions?[.url] as? URL
            window = UIWindow(frame: UIScreen.main.bounds)
            launch = LaunchCoordinator(window: window!)
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
}

