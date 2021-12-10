//
//  AuthStore.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit

typealias LoginHandler = (Result<User, ApiError>) -> Void

class AuthStore {
    private let userDefaultKey = "AuthStore_user"
    
    static let shared = AuthStore()
    
    weak var delegate: AuthStoreDelegate?
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultKey) {
            do {
                user = try JSONDecoder().decode(User.self, from: data)
            }
            catch {
                print("decode user error \(error)")
            }
        }
    }
    
    var isLogin: Bool { user != nil }
    
    var user: User?

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: userDefaultKey)
        delegate?.authStoreDidLogout(self)
    }
    
    func processLoginSuccessUserInfo(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.setValue(data, forKey: userDefaultKey)
        }
        catch {
            print("encode user error \(error.localizedDescription)")
        }
        self.user = user
        delegate?.authStoreDidLoginSuccess(self, user: user)
        
        #if DEBUG
        var debugUsers = (try? JSONDecoder().decode([User].self, from: UserDefaults.standard.data(forKey: "debugUsers") ?? Data())) ?? []
        if let index = debugUsers.firstIndex(where: { $0.userUUID == user.userUUID }) {
            debugUsers[index] = user
        } else {
            debugUsers.append(user)
        }
        if let newData = try? JSONEncoder().encode(debugUsers) {
            UserDefaults.standard.set(newData, forKey: "debugUsers")
        }
        #endif
    }
}
