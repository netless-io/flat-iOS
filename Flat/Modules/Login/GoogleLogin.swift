//
//  GoogleLogin.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/16.
//  Copyright © 2023 agora.io. All rights reserved.
//

import SafariServices
import UIKit

class GoogleLogin: LaunchItem {
    private var unload: (() -> Void)?

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        guard url?.absoluteString == "x-agora-flat-client://open",
              handler != nil else { return false }
        return true
    }

    deinit {
        unload?()
    }

    func shouldHandle(userActivity _: NSUserActivity, scene: UIScene) -> Bool {
        false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {
        guard let handler else { return }
        safariVC?.showActivityIndicator()
        ApiProvider.shared.request(fromApi: AuthProcessRequest(uuid: uuid)) { [weak self] result in
            self?.safariVC?.stopActivityIndicator()
            handler(result)
        }
        unload?()
    }

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {}

    let uuid: String = UUID().uuidString

    var handler: LoginHandler?

    weak var safariVC: SFSafariViewController?

    func startLogin(withAuthStore authStore: AuthStore, launchCoordinator: LaunchCoordinator, sender: UIButton, completionHandler: @escaping LoginHandler) {
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { [weak self] r in
            guard let self else { return }
            switch r {
            case .success:
                let controller = SFSafariViewController(url: self.googleLoginURL)
                controller.modalPresentationStyle = .pageSheet
                sender.viewController()?.present(controller, animated: true)
                let launchItemIdentifier = self.uuid
                launchCoordinator.registerLaunchItem(self, identifier: launchItemIdentifier)
                self.unload = { [weak launchCoordinator] in
                    launchCoordinator?.removeLaunchItem(fromIdentifier: launchItemIdentifier)
                }
                self.handler = { [weak authStore, weak self] result in
                    guard let self else { return }
                    if case let .success(user) = result {
                        authStore?.processLoginSuccessUserInfo(user)
                    }
                    completionHandler(result)
                    self.unload?()
                }
                self.safariVC = controller
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
    
    var googleLoginURL: URL {
        let env = Env()
        let clientId = env.googleClientId
        let redirectUrl = env.baseURL + "/v1/login/google/callback"
        let scopes = ["openid", "https://www.googleapis.com/auth/userinfo.profile"]
        let scope = scopes.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://accounts.google.com/o/oauth2/v2/auth?response_type=code&access_type=online&scope=\(scope)&client_id=\(clientId)&redirect_uri=\(redirectUrl)&state=\(uuid)")!
    }
}
