//
//  AppDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Fastboard
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import IQKeyboardManagerSwift
import Kingfisher
import Siren
import UIKit

var globalSessionId = UUID().uuidString

var didStartGoogleAnalytics = false
func startGoogleAnalytics() {
    guard !didStartGoogleAnalytics else { return }
    FirebaseApp.configure()
    if let uid = AuthStore.shared.user?.userUUID, !uid.isEmpty {
        Crashlytics.crashlytics().setUserID(uid)
    }
    didStartGoogleAnalytics = true
}

var isFirstTimeLaunch: Bool {
    UserDefaults.standard.value(forKey: "isFirstTimeLaunch") != nil
}

func setDidFirstTimeLaunch() {
    UserDefaults.standard.setValue(true, forKey: "isFirstTimeLaunch")
}

var globalLaunchCoordinator: LaunchCoordinator!

func configAppearance() {
    FastRoomThemeManager.shared.updateIcons(using: Bundle.main)
    FastRoomControlBar.appearance().borderWidth = commonBorderWidth

    UISwitch.appearance().onTintColor = .color(type: .primary)

    IQKeyboardManager.shared.enable = true
    IQKeyboardManager.shared.enableAutoToolbar = false
    IQKeyboardManager.shared.shouldResignOnTouchOutside = true
    IQKeyboardManager.shared.keyboardDistanceFromTextField = 10
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var checkOSSVersionObserver: NSObjectProtocol?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        bootstrapLogger()
        globalLaunchCoordinator = .init(authStore: AuthStore.shared, defaultLaunchItems: [JoinRoomLaunchItem(), FileShareLaunchItem(), ReplayLaunchItem()])
        if isFirstTimeLaunch {
            ApiProvider.shared.startEmptyRequestForWakingUpNetworkAlert()
            setDidFirstTimeLaunch()
        }
        tryPreloadWhiteboard()
        processMethodExchange()
        registerThirdPartSDK()
        configAppearance()

        #if DEBUG
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
            URLSession.shared.dataTask(with: request) { data, _, _ in
                URLCache.shared.removeCachedResponse(for: request)
                if let data,
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let force_min_version = obj["force_min_version"],
                   let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                   currentVersion.compare(force_min_version, options: .numeric) == .orderedAscending
                {
                    Siren.shared.rulesManager = .init(globalRules: .critical, showAlertAfterCurrentVersionHasBeenReleasedForDays: 0)
                    Siren.shared.wail(performCheck: .onDemand)
                } else {
                    Siren.shared.wail()
                }
            }.resume()
        }

        return true
    }

    func registerThirdPartSDK() {
        WXApi.registerApp(Env().weChatAppId, universalLink: "https://flat-api.whiteboard.agora.io")
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

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let activity = options.userActivities.first
        let activityType = activity?.activityType ?? ""
        logger.info("multiwindow: configurationForConnecting \(activityType)")
        switch activityType {
        case NSUserActivity.Classroom:
            connectingSceneSession.userInfo = activity?.userInfo as? [String: Any]
            return UISceneConfiguration(name: NSUserActivity.Classroom, sessionRole: connectingSceneSession.role)
        default:
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
    }

    // MARK: Orientation

    func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
        .all
    }
}

extension NSUserActivity {
    // Should keep the same as ConfigurationName value in plist
    static var Classroom: String { "Classroom" }
}
