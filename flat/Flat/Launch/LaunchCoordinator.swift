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
    let window: UIWindow
    
    var afterLoginImplementations: [((LaunchCoordinator)->Void)] = []
    
    // All the registed launchItem will be stored here
    fileprivate var launchItems: [String: LaunchItem] = [:] {
        didSet {
            #if DEBUG
            print("launchItems update", launchItems)
            #endif
        }
    }
    
    init(window: UIWindow, authStore: AuthStore) {
        self.window = window
        authStore.delegate = self
    }
    
    func registerLaunchItem(_ item: LaunchItem, identifier: String) {
        launchItems[identifier] = item
    }
    
    func removeLaunchItem(fromIdentifier identifier: String) {
        launchItems.removeValue(forKey: identifier)
    }
    
    func start(withLaunchUserActivity userActivity: NSUserActivity) -> Bool {
        configRootWith(isLogin: AuthStore.shared.isLogin)
        let targetItems = launchItems.map { $0.value }.filter { $0.shouldHandle(userActivity: userActivity) }
        for item in targetItems {
            item.immediateImplementation(withLaunchCoordinator: self)
        }
        self.afterLoginImplementations = targetItems.compactMap { $0.afterLoginImplementation }
        return !targetItems.isEmpty
    }
    
    func start(withLaunchUrl launchUrl: URL? = nil) {
        configRootWith(isLogin: AuthStore.shared.isLogin)
        let targetItems = launchItems.map { $0.value }.filter { $0.shouldHandle(url: launchUrl) }
        for item in targetItems {
            item.immediateImplementation(withLaunchCoordinator: self)
        }
        self.afterLoginImplementations = targetItems.compactMap { $0.afterLoginImplementation }
    }
    
    func reboot() {
        window.rootViewController = AuthStore.shared.isLogin ? MainSplitViewController() : LoginViewController()
    }
    
    // MARK: - Private
    fileprivate func configRootWith(isLogin: Bool) {
        flatGenerator.token = AuthStore.shared.user?.token
        if isLogin {
            guard let _ = window.rootViewController as? MainTabbarController else {
                window.rootViewController = MainSplitViewController()
                window.makeKeyAndVisible()
                return
            }
        } else {
            guard let _ = window.rootViewController as? LoginViewController else {
                window.rootViewController = LoginViewController()
                window.makeKeyAndVisible()
                return
            }
        }
    }
}

extension LaunchCoordinator: AuthStoreDelegate {
    func authStoreDidLoginSuccess(_ authStore: AuthStore, user: User) {
        configRootWith(isLogin: true)
        afterLoginImplementations.forEach { $0(self) }
        afterLoginImplementations = []
    }
    
    func authStoreDidLogout(_ authStore: AuthStore) {
        configRootWith(isLogin: false)
    }
}
