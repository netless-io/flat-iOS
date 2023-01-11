//
//  SceneManager.swift
//  Flat
//
//  Created by xuyunshi on 2023/1/5.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

fileprivate func randomForegroundWindow() -> UIWindow? {
    let connectedWindowScenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
    if let activeScene = connectedWindowScenes.first(where: { $0.activationState == .foregroundActive }) {
        return activeScene.windows.first(where: \.isKeyWindow)
    }
    if let inactiveScene = connectedWindowScenes.first(where: { $0.activationState == .foregroundInactive }) {
        return inactiveScene.windows.first(where: \.isKeyWindow)
    }
    return nil
}

class SceneManager {
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onLoginSuccess), name: loginSuccessNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLogout), name: logoutNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onJwtExpire), name: jwtExpireNotificationName, object: nil)
        
    }

    static let shared = SceneManager()

    // Retain the windows related to UIWindowScene
    var windowMap: [String: UIWindow] = [:]
    // Retain the setuped scene identifiers
    var setupedSceneIdentifierSet: Set<String> = .init()
    
    func startConnect(scene: UIScene, connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let identifier = windowScene.session.persistentIdentifier
        if !setupedSceneIdentifierSet.contains(identifier) {
            logger.info("sceneManager: setup \(identifier)")
            config(windowScene: windowScene, user: AuthStore.shared.user)
            setupedSceneIdentifierSet.insert(identifier)
        }

        if let userActivity = connectionOptions.userActivities.first {
            _ = globalLaunchCoordinator.start(withLaunchUserActivity: userActivity, scene: scene)
        } else {
            globalLaunchCoordinator.start(scene: scene, withLaunchUrl: connectionOptions.urlContexts.first?.url)
        }
    }
    
    func updateWindowSceneTrait(_ windowScene: UIWindowScene) {
        // To avoid the viewcontroller replace complex, only config the root viewcontroller now.
        config(windowScene: windowScene, user: AuthStore.shared.user)
    }
    
    func disconnect(scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let identifier = windowScene.session.persistentIdentifier
        logger.info("sceneManager: disconnect \(identifier)")
        windowMap.removeValue(forKey: windowScene.session.persistentIdentifier)
        setupedSceneIdentifierSet.remove(identifier)
    }
    
    func reboot(scene: UIWindowScene) {
        config(windowScene: scene, user: AuthStore.shared.user)
    }
    
    func refreshMultiWindowPreview() {
        windowMap.compactMap(\.value.windowScene?.session)
            .forEach { UIApplication.shared.requestSceneSessionRefresh($0) }
    }

    // MARK: - AuthStore

    @objc func onLoginSuccess(_ notification: Notification) {
        guard let user = notification.userInfo?["user"] as? User else { return }
        for (identifier, window) in windowMap {
            guard let scene = window.windowScene else { return }
            logger.info("sceneManager: setup with login success \(identifier)")
            config(windowScene: scene, user: user)
        }
        refreshMultiWindowPreview()
    }

    @objc func onLogout() {
        for (identifier, window) in windowMap {
            guard let scene = window.windowScene else { return }
            logger.info("sceneManager: clean scene \(identifier)")
            config(windowScene: scene, user: nil)
        }
        refreshMultiWindowPreview()
    }

    @objc func onJwtExpire() {
        guard let root = randomForegroundWindow()?.rootViewController else { return }
        if let _ = root.presentedViewController {
            root.dismiss(animated: false)
        }
        root.showAlertWith(message: FlatApiError.JWTSignFailed.localizedDescription) {
            AuthStore.shared.logout()
        }
    }
}

extension SceneManager {
    func config(windowScene: UIWindowScene, user: User?) {
        let window: UIWindow
        if let persistWindow = windowMap[windowScene.session.persistentIdentifier] {
            window = persistWindow
        } else {
            window = UIWindow(frame: windowScene.coordinateSpace.bounds)
            window.windowScene = windowScene
            windowMap[windowScene.session.persistentIdentifier] = window
        }
        Theme.shared.setupWindowTheme(window)
        defer {
            window.makeKeyAndVisible()                                                    
        }
        if let user {
            startGoogleAnalytics()
            if user.hasPhone {
                window.rootViewController = createMainContainer(for: window)
            } else {
                let root = LoginViewController()
                window.rootViewController = root
                root.present(BindPhoneViewController(), animated: true)
            }
        } else {
            window.rootViewController = LoginViewController()
        }
    }
    
    func createMainContainer(for window: UIWindow) -> UIViewController {
        func compactMain() -> UIViewController {
            MainTabBarController()
        }

        func oldPadMain() -> UIViewController {
            let vc = MainSplitViewController()
            // Line for splitViewController
            let tabbar = MainTabBarController()
            tabbar.view.addLine(direction: .right, color: .color(light: .grey1, dark: .clear))
            vc.viewControllers = [tabbar]
            vc.preferredDisplayMode = .oneBesideSecondary
            return vc
        }

        if #available(iOS 14.0, *) {
            if window.traitCollection.hasCompact {
                return compactMain()
            }
            let vc = MainSplitViewController(style: .tripleColumn)
            if #available(iOS 14.5, *) {
                vc.displayModeButtonVisibility = .never
            }
            vc.preferredDisplayMode = .twoBesideSecondary
            vc.preferredSplitBehavior = .tile
            vc.showsSecondaryOnlyButton = false
            vc.preferredPrimaryColumnWidth = 64
            vc.preferredSupplementaryColumnWidth = 360
            let sideVC = RegularSideBarViewController()
            vc.setViewController(sideVC, for: .primary)
            vc.setViewController(vc.emptyDetailController, for: .secondary)
            return vc
        } else {
            if window.traitCollection.hasCompact {
                return compactMain()
            }
            return oldPadMain()
        }
    }
}
