//
//  AuthStore.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

let avatarUpdateNotificationName: Notification.Name = .init(rawValue: "avatarUpdateNotification")
let loginSuccessNotificationName: Notification.Name = .init("loginSuccessNotification")
let logoutNotificationName: Notification.Name = .init("logoutNotification")
let jwtExpireNotificationName: Notification.Name = .init("jwtExpireNotification")

typealias LoginHandler = (Result<User, Error>) -> Void

struct AccountLoginInfo: Codable {
    var account: AccountType
    var regionCode: String
    var inputText: String // Not include country phone code.
    var pwd: String
}

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
              // Logger may not be ready...
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  globalLogger.error("decode user error, \(error)")
              }
            }
        }
    }
    
    var unsetDefaultProfileUserUUID: String {
        get {
            (UserDefaults.standard.value(forKey: "unsetDefaultProfileSet") as? String) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "unsetDefaultProfileSet")
        }
    }

    var lastAccountLoginInfo: AccountLoginInfo? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "lastAccountLoginInfo"),
                  let model = try? JSONDecoder().decode(AccountLoginInfo.self, from: data)
            else { return nil }
            return model
        }
        set {
            guard let newValue else {
                UserDefaults.standard.set(nil, forKey: "lastAccountLoginInfo")
                return
            }
            guard let data = try? JSONEncoder().encode(newValue) else {
                UserDefaults.standard.set(nil, forKey: "lastAccountLoginInfo")
                return
            }
            UserDefaults.standard.set(data, forKey: "lastAccountLoginInfo")
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
    }

    func processLoginSuccessUserInfo(_ user: User, relogin: Bool = true) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.setValue(data, forKey: userDefaultKey)
        } catch {
            globalLogger.error("encode user error \(error)")
        }
        self.user = user
        if relogin {
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
                globalLogger.error("post jwt expire notification")
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
