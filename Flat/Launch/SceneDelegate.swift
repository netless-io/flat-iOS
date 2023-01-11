//
//  SceneDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        logger.info("multiwindow: willConnect to \(scene.session.persistentIdentifier)")
        SceneManager.shared.startConnect(scene: scene, connectionOptions: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        logger.info("multiwindow: open url contexts \(URLContexts)")
        // TODO: url to userActivity
        guard let url = URLContexts.first?.url else { return }
        globalLaunchCoordinator.start(scene: scene, withLaunchUrl: url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        logger.info("multiwindow: continue \(userActivity)")
        globalLaunchCoordinator.start(withLaunchUserActivity: userActivity, scene: scene)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        logger.info("multiwindow: disconnect \(scene.session.persistentIdentifier)")
        SceneManager.shared.disconnect(scene: scene)
    }
    
    // MARK: - WindowSceneDelegate
    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        guard windowScene.activationState == .foregroundInactive || windowScene.activationState == .foregroundActive else { return }
        if previousTraitCollection.horizontalSizeClass == windowScene.traitCollection.horizontalSizeClass,
           previousTraitCollection.verticalSizeClass == windowScene.traitCollection.verticalSizeClass {
            return
        }
        logger.info("multiwindow: update traitCollection \(windowScene.traitCollection)")
        SceneManager.shared.updateWindowSceneTrait(windowScene)
    }
}
     
