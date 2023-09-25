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

        if #available(iOS 15.0, *) {
            if let windowScene = scene as? UIWindowScene {
                let launchAnimationView = UIView(frame: windowScene.screen.bounds)
                let logo = UIImageView(image: UIImage(named: "login_icon"))
                launchAnimationView.addSubview(logo)
                logo.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                }
                let window = windowScene.keyWindow
                let beginScale = CGFloat(1.1)
                window?.transform = .init(scaleX: beginScale, y: beginScale)
                launchAnimationView.transform = .init(scaleX: 1 / beginScale, y: 1 / beginScale)
                window?.addSubview(launchAnimationView)
                UIView.animate(withDuration: 2 / 3.0) {
                    window?.transform = .identity
                    launchAnimationView.alpha = 0
                    launchAnimationView.transform = .init(scaleX: 1 / beginScale * 0.8, y: 1 / beginScale * 0.8)
                } completion: { _ in
                    launchAnimationView.removeFromSuperview()
                }
            }
        }
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

    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.blur(false)
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.blur(true)
        }
    }
    
    // MARK: - WindowSceneDelegate
    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        guard UIApplication.shared.supportsMultipleScenes else { return }
        guard windowScene.activationState == .foregroundInactive || windowScene.activationState == .foregroundActive else { return }
        if previousTraitCollection.horizontalSizeClass == windowScene.traitCollection.horizontalSizeClass,
           previousTraitCollection.verticalSizeClass == windowScene.traitCollection.verticalSizeClass {
            return
        }
        logger.info("multiwindow: update traitCollection \(windowScene.traitCollection)")
        SceneManager.shared.updateWindowSceneTrait(windowScene)
    }
}
     
