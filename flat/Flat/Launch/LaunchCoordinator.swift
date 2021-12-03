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
    
    var hitedItems: [LaunchItem] = []
    var afterLoginImplementations: [((LaunchCoordinator)->Void)] = []
    
    var authStore: AuthStore
    
    // All the registed launchItem will be stored here
    fileprivate var launchItems: [String: LaunchItem] = [:] {
        didSet {
            #if DEBUG
            print("launchItems update", launchItems)
            #endif
        }
    }
    
    init(window: UIWindow, authStore: AuthStore, defaultLaunchItems: [LaunchItem]) {
        self.window = window
        self.authStore = authStore
        authStore.delegate = self
        defaultLaunchItems.forEach { registerLaunchItem($0, identifier: String(describing: $0)) }
    }
    
    func registerLaunchItem(_ item: LaunchItem, identifier: String) {
        launchItems[identifier] = item
    }
    
    func removeLaunchItem(fromIdentifier identifier: String) {
        launchItems.removeValue(forKey: identifier)
    }
    
    func start(withLaunchUserActivity userActivity: NSUserActivity) -> Bool {
        configRootWith(isLogin: authStore.isLogin)
        hitedItems = launchItems.map { $0.value }.filter { $0.shouldHandle(userActivity: userActivity) }
        hitedItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitedItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
            hitedItems = []
        }
        return !hitedItems.isEmpty
    }
    
    func start(withLaunchUrl launchUrl: URL? = nil) {
        configRootWith(isLogin: authStore.isLogin)
        hitedItems = launchItems.map { $0.value }.filter { $0.shouldHandle(url: launchUrl) }
        hitedItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitedItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
            hitedItems = []
        }
    }
    
    func reboot() {
        window.rootViewController = authStore.isLogin ? MainSplitViewController() : LoginViewController()
    }
    
    // MARK: - Private
    fileprivate func configRootWith(isLogin: Bool) {
        flatGenerator.token = authStore.user?.token
        if isLogin {
            guard let _ = window.rootViewController as? MainSplitViewController else {
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
        hitedItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
        hitedItems = []
    }
    
    func authStoreDidLogout(_ authStore: AuthStore) {
        configRootWith(isLogin: false)
    }
}
