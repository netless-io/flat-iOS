//
//  AuthStore.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit

let avatarUpdateNotificationName: Notification.Name = .init(rawValue: "avatarUpdateNotificationName")

typealias LoginHandler = (Result<User, ApiError>) -> Void

enum BindingType: Int, CaseIterable, Codable {
    case WeChat = 0
    case Apple
    case Github

    var identifierString: String { String(describing: self) }
}

class AuthStore {
    private let userDefaultKey = "AuthStore_user"

    static let shared = AuthStore()

    weak var delegate: AuthStoreDelegate?

    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultKey) {
            do {
                user = try JSONDecoder().decode(User.self, from: data)
                flatGenerator.token = user?.token
            } catch {
                logger.error("decode user error, \(error)")
            }
        }
    }

    var isLogin: Bool { user != nil }

    var user: User? {
        didSet {
            flatGenerator.token = user?.token
        }
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: userDefaultKey)
        delegate?.authStoreDidLogout(self)
    }

    func processBindPhoneSuccess() {
        guard var newUser = user else {
            return
        }
        newUser.hasPhone = true
        processLoginSuccessUserInfo(newUser)
    }

    func processLoginSuccessUserInfo(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.setValue(data, forKey: userDefaultKey)
        } catch {
            logger.error("encode user error \(error)")
        }
        self.user = user
        delegate?.authStoreDidLoginSuccess(self, user: user)
    }

    // MARK: - Update info

    func updateName(_ name: String) {
        user?.name = name
        if let user = user {
            processLoginSuccessUserInfo(user)
        }
    }

    func updateAvatar(_ url: URL) {
        user?.avatar = url
        if let user = user {
            processLoginSuccessUserInfo(user)
        }
        NotificationCenter.default.post(name: avatarUpdateNotificationName, object: nil)
    }

    func updateToken(_ token: String) {
        user?.token = token
        if let user = user {
            processLoginSuccessUserInfo(user)
        }
    }
}
