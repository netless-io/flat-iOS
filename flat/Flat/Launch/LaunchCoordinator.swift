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
    
    var afterLoginImplementation: ((LaunchCoordinator)->Void)?
    
    var launchItems: [LaunchItem] = [AuthStore.shared]
    
    init(window: UIWindow) {
        self.window = window
        AuthStore.shared.delegate = self
    }
    
    func start(withLaunchUrl launchUrl: URL? = nil) {
        configRootWith(isLogin: AuthStore.shared.isLogin)
        if let launchUrl = launchUrl {
            if let item = launchItems.first(where: { $0.shouldHandle(url: launchUrl) }) {
                item.immediateImplementation(withLaunchCoordinator: self)
                self.afterLoginImplementation = item.afterLoginImplementation
            }
        }
    }
    
    func reboot() {
        window.rootViewController = AuthStore.shared.isLogin ? MainSplitViewController() : LoginViewController()
    }
    
    func configRootWith(isLogin: Bool) {
        flatGenerator.token = AuthStore.shared.user?.token
        if isLogin {
            guard let _ = window.rootViewController as? MainTabbarController else {
//                window.rootViewController = MainTabbarController()
                
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
        afterLoginImplementation?(self)
        afterLoginImplementation = nil
    }
    
    func authStoreDidLoginFail(_ authStore: AuthStore, error: Error) {
        
    }
    
    func authStoreDidLogout(_ authStore: AuthStore) {
        configRootWith(isLogin: false)
    }
}
