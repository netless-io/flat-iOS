//
//  AuthStore.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import FirebaseCrashlytics
import Foundation
import UIKit
import RxSwift

let avatarUpdateNotificationName: Notification.Name = .init(rawValue: "avatarUpdateNotification")
let loginSuccessNotificationName: Notification.Name = .init("loginSuccessNotification")
let signUpSuccessNotificationName: Notification.Name = .init("signUpSuccessNotificationName")
let logoutNotificationName: Notification.Name = .init("logoutNotification")
let jwtExpireNotificationName: Notification.Name = .init("jwtExpireNotification")

typealias LoginHandler = (Result<User, Error>) -> Void

class AuthStore {
    private let userDefaultKey = "AuthStore_user"

    static let shared = AuthStore()
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultKey) {
            do {
                user = try JSONDecoder().decode(User.self, from: data)
                flatGenerator.token = user?.token
                observeFirstJWTExpire()
            } catch {
                logger.error("decode user error, \(error)")
            }
        }
    }

    var disposeBag = DisposeBag()
    
    var isLogin: Bool { user != nil }

    var user: User? {
        didSet {
            flatGenerator.token = user?.token
        }
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: userDefaultKey)
        NotificationCenter.default.post(name: logoutNotificationName, object: nil)
    }

    func processBindPhoneSuccess() {
        guard var newUser = user else {
            return
        }
        newUser.hasPhone = true
        processLoginSuccessUserInfo(newUser)
        NotificationCenter.default.post(name: signUpSuccessNotificationName, object: nil)
    }

    func processLoginSuccessUserInfo(_ user: User, relogin: Bool = true) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.setValue(data, forKey: userDefaultKey)
        } catch {
            logger.error("encode user error \(error)")
        }
        self.user = user
        if relogin {
            Crashlytics.crashlytics().setUserID(user.userUUID)
            NotificationCenter.default.post(name: loginSuccessNotificationName, object: nil, userInfo: ["user": user])
            observeFirstJWTExpire()
        }
    }

    func observeFirstJWTExpire() {
        FlatResponseHandler
            .jwtExpireSignal
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { weakSelf, _ in
                logger.error("post jwt expire notification")
                ApiProvider.shared.cancelAllTasks()
                NotificationCenter.default.post(name: jwtExpireNotificationName, object: nil)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Update info

    func updateName(_ name: String) {
        user?.name = name
        if let user {
            processLoginSuccessUserInfo(user, relogin: false)
        }
    }

    func updateAvatar(_ url: URL) {
        user?.avatar = url.absoluteString
        if let user {
            processLoginSuccessUserInfo(user, relogin: false)
        }
        NotificationCenter.default.post(name: avatarUpdateNotificationName, object: nil)
    }

    func updateToken(_ token: String) {
        user?.token = token
        if let user {
            processLoginSuccessUserInfo(user)
        }
    }
}
