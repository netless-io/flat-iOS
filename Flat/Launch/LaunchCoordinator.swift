//
//  Launch.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit
import RxSwift

class LaunchCoordinator {
    let window: UIWindow
    
    var disposeBag = DisposeBag()
    
    var hitItems: [LaunchItem] = []
    var afterLoginImplementations: [((LaunchCoordinator)->Void)] = []
    
    var authStore: AuthStore
    // All the registerd launchItem will be stored here
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
        
        if authStore.isLogin {
            observeFirstJWTExpire()
        }
        Theme.shared.window = window
    }
    
    func registerLaunchItem(_ item: LaunchItem, identifier: String) {
        launchItems[identifier] = item
    }
    
    func removeLaunchItem(fromIdentifier identifier: String) {
        launchItems.removeValue(forKey: identifier)
    }
    
    func start(withLaunchUserActivity userActivity: NSUserActivity) -> Bool {
        configRootWith(isLogin: authStore.isLogin)
        hitItems = launchItems.map { $0.value }.filter { $0.shouldHandle(userActivity: userActivity) }
        hitItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
            hitItems = []
        }
        return !hitItems.isEmpty
    }
    
    func start(withLaunchUrl launchUrl: URL? = nil) {
        configRootWith(isLogin: authStore.isLogin)
        hitItems = launchItems.map { $0.value }.filter { $0.shouldHandle(url: launchUrl) }
        hitItems.forEach { $0.immediateImplementation(withLaunchCoordinator: self) }
        if authStore.isLogin, let user = authStore.user {
            hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
            hitItems = []
        }
    }
    
    func reboot() {
        window.rootViewController = authStore.isLogin ? createMainContainer() : LoginViewController()
    }
    
    func createMainContainer() -> UIViewController {
        func compactMain() -> UIViewController {
            return MainTabBarController()
        }
        
        func oldPadMain() -> UIViewController {
            let vc = MainSplitViewController()
            vc.viewControllers = [MainTabBarController()]
            vc.preferredDisplayMode = .oneBesideSecondary
            return vc
        }
        
        if #available(iOS 14.0, *) {
            if window.traitCollection.hasCompact {
                return compactMain()
            }
            let vc = MainSplitViewController(style: .tripleColumn)
            vc.preferredDisplayMode = .twoBesideSecondary
            vc.preferredSplitBehavior = .tile
            vc.showsSecondaryOnlyButton = false
            if #available(iOS 14.5, *) {
                vc.displayModeButtonVisibility = .always
            }
            vc.preferredSupplementaryColumnWidthFraction = 0.375
            vc.preferredPrimaryColumnWidthFraction = 0.375 / 2
            vc.minimumPrimaryColumnWidth = 144
            vc.setViewController(BaseNavigationViewController(rootViewController: SidebarViewController()), for: .primary)
            vc.setViewController(HomeViewController(), for: .supplementary)
            vc.setViewController(vc.emptyDetailController, for: .secondary)
            vc.primaryBackgroundStyle = .sidebar
            return vc
        } else {
            return oldPadMain()
        }
    }
    
    // MARK: - Private
    fileprivate func configRootWith(isLogin: Bool) {
        flatGenerator.token = authStore.user?.token
        if isLogin {
            guard let _ = window.rootViewController as? MainContainer else {
                window.rootViewController = createMainContainer()
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
    
    func observeFirstJWTExpire() {
        FlatResponseHandler
            .jwtExpireSignal
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { weakSelf, _ in
                guard let root = weakSelf.window.rootViewController else { return }
                if let _ = root.presentedViewController { root.dismiss(animated: false, completion: nil) }
                ApiProvider.shared.cancelAllTasks()
                root.showAlertWith(message: FlatApiError.JWTSignFailed.localizedDescription) {
                    AuthStore.shared.logout()
                }
            })
            .disposed(by: disposeBag)
    }
}

extension LaunchCoordinator: AuthStoreDelegate {
    func authStoreDidLoginSuccess(_ authStore: AuthStore, user: User) {
        configRootWith(isLogin: true)
        hitItems.forEach { $0.afterLoginSuccessImplementation(withLaunchCoordinator: self, user: user)}
        hitItems = []
        
        observeFirstJWTExpire()
    }
    
    func authStoreDidLogout(_ authStore: AuthStore) {
        configRootWith(isLogin: false)
    }
}
