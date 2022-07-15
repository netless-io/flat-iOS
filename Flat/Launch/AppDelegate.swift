//
//  AppDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Kingfisher
import Fastboard
import Siren

var globalLaunchCoordinator: LaunchCoordinator? {
    if #available(iOS 13.0, *) {
        return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.launch
    } else {
        return (UIApplication.shared.delegate as? AppDelegate)?.launch
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var launch: LaunchCoordinator?
    var checkOSSVersionObserver: NSObjectProtocol?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApiProvider.shared.startEmptyRequestForWakingUpNetworkAlert()
        processMethodExchange()
        configAppearance()
        registerThirdPartSDK()
        if #available(iOS 13, *) {
            // SceneDelegate
        } else {
            let url = launchOptions?[.url] as? URL
            window = UIWindow(frame: UIScreen.main.bounds)
            launch = LaunchCoordinator(window: window!, authStore: AuthStore.shared, defaultLaunchItems: [JoinRoomLaunchItem(), FileShareLaunchItem()])
            launch?.start(withLaunchUrl: url)
        }
#if DEBUG
        do {
            let injectionBundle = Bundle.init(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")
            if let bundle = injectionBundle {
                try bundle.loadAndReturnError()
            } else {
                debugPrint("Injection注入失败,未能检测到Injection")
            }
            
        } catch {
            debugPrint("Injection注入失败\(error)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard AuthStore.shared.isLogin else { return }
            // Cancel all the previous upload task, for old task will block the new upload
            ApiProvider.shared.request(fromApi: CancelUploadRequest(fileUUIDs: [])) { _ in
            }
        }
#endif
        
        Siren.shared.apiManager = .init(country: .china)
        Siren.shared.rulesManager = .init(globalRules: .relaxed)
        checkOSSVersionObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            let url = URL(string: "https://flat-storage.oss-cn-hangzhou.aliyuncs.com/versions/latest/stable/iOS/ios_latest.json")!
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
            URLSession.shared.dataTask(with: request) { data, response, error in
                URLCache.shared.removeCachedResponse(for: request)
                if let data = data,
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let force_min_version = obj["force_min_version"],
                   let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                   currentVersion.compare(force_min_version, options: .numeric) == .orderedAscending {
                    Siren.shared.rulesManager = .init(globalRules: .critical)
                    Siren.shared.wail(performCheck: .onDemand)
                } else {
                    Siren.shared.wail()
                }
            }.resume()
        }

        return true
    }
    
    func registerThirdPartSDK() {
        WXApi.registerApp(Env().wechatAppId, universalLink: "https://flat-api.whiteboard.agora.io")
    }
    
    func configAppearance() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 10
    }
    
    func processMethodExchange() {
        methodExchange(cls: UIViewController.self,
                       originalSelector: #selector(UIViewController.traitCollectionDidChange(_:)),
                       swizzledSelector: #selector(UIViewController.exchangedTraitCollectionDidChange(_:)))
        
        methodExchange(cls: UIView.self,
                       originalSelector: #selector(UIView.traitCollectionDidChange(_:)),
                       swizzledSelector: #selector(UIView.exchangedTraitCollectionDidChange(_:)))
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
    

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let _ = launch?.start(withLaunchUserActivity: userActivity)
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .all
    }
}

