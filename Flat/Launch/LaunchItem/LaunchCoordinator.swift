//
//  Launch.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit

class LaunchCoordinator {
    var hitItems: [LaunchItem] = []
    var afterLoginImplementations: [(LaunchCoordinator) -> Void] = []

    var authStore: AuthStore
    // All the registered launchItem will be stored here
    private var launchItems: [String: LaunchItem] = [:] {
        didSet {
            logger.info("launchItems update, \(launchItems)")
        }
    }

    init(authStore: AuthStore, defaultLaunchItems: [LaunchItem]) {
        self.authStore = authStore
        defaultLaunchItems.forEach { registerLaunchItem($0, identifier: String(describing: $0)) }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLoginSuccess),
                                               name: loginSuccessNotificationName,
                                               object: nil)
    }
    
    @objc func onLoginSuccess(_ notification: Notification) {
        guard let user = notification.userInfo?["user"] as? User else { return }
        hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user) }
        hitItems = []
        updateAliSlsLogger(uid: user.userUUID)
    }
    

    func registerLaunchItem(_ item: LaunchItem, identifier: String) {
        launchItems[identifier] = item
    }

    func removeLaunchItem(fromIdentifier identifier: String) {
        launchItems.removeValue(forKey: identifier)
    }

    @discardableResult
    func start(withLaunchUserActivity userActivity: NSUserActivity, scene: UIScene) -> Bool {
        hitItems = launchItems.map(\.value).filter { $0.shouldHandle(userActivity: userActivity, scene: scene) }
        hitItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user) }
            hitItems = []
        }
        return !hitItems.isEmpty
    }

    func start(scene: UIScene, withLaunchUrl launchUrl: URL? = nil) {
        hitItems = launchItems.map(\.value).filter { $0.shouldHandle(url: launchUrl, scene: scene) }
        hitItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user) }
            hitItems = []
        }
    }
}
