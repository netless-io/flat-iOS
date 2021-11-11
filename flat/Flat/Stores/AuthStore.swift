//
//  AuthStore.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit

typealias LoginHanlder = (Result<User, ApiError>) -> Void

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
    
    var githubLogin: GithubLogin?
    
    func startGithubLogin(completionHandler: @escaping LoginHanlder) {
        if githubLogin == nil {
            githubLogin = GithubLogin()
        }
        githubLogin?.startLogin(completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                self.processNewUser(user)
            case .failure(let error):
                self.delegate?.authStoreDidLoginFail(self, error: error)
            }
            if case .success(let user) = result {
                self.processNewUser(user)
            }
            completionHandler(result)
        })
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: userDefaultKey)
        delegate?.authStoreDidLogout(self)
    }
    
    func processNewUser(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.setValue(data, forKey: userDefaultKey)
        }
        catch {
            print("encode user error \(error.localizedDescription)")
        }
        self.user = user
        delegate?.authStoreDidLoginSuccess(self, user: user)
    }
}

extension AuthStore: LaunchItem {
    func shouldHandle(url: URL) -> Bool {
        guard githubLogin?.shouldHandle(url: url) ?? false else { return false }
        return true
    }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator) {
        githubLogin?.immediateImplementation(withLaunchCoordinator: launchCoordinator)
    }
    
    var afterLoginImplementation: ((LaunchCoordinator) -> Void)? {
        githubLogin?.afterLoginImplementation
    }
}
