//
//  SceneDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var launch: LaunchCoordinator?
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        print(LocaleManager.languageCode ?? "local")
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        launch = .init(window: window!, authStore: AuthStore.shared, defaultLaunchItems: [JoinRoomLaunchItem(), FileShareLaunchItem()])
        if let userActivity = connectionOptions.userActivities.first {
            _ = launch?.start(withLaunchUserActivity: userActivity)
        } else {
            launch?.start(withLaunchUrl: connectionOptions.urlContexts.first?.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // TODO: url to userActivity
        guard let url = URLContexts.first?.url else { return }
        launch?.start(withLaunchUrl: url)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        _ = launch?.start(withLaunchUserActivity: userActivity)
    }
}

