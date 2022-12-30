//
//  GithubLogin.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

class GithubLogin: LaunchItem {
    var removeLaunchItemFromLaunchCoordinator: (() -> Void)?

    func shouldHandle(url: URL?) -> Bool {
        guard url?.absoluteString == "x-agora-flat-client://open",
              handler != nil else { return false }
        return true
    }

    deinit {
        removeLaunchItemFromLaunchCoordinator?()
    }

    func shouldHandle(userActivity _: NSUserActivity) -> Bool {
        false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {
        guard let handler else { return }
        safariVC?.showActivityIndicator()
        ApiProvider.shared.request(fromApi: AuthProcessRequest(uuid: uuid)) { [weak self] result in
            self?.safariVC?.stopActivityIndicator()
            handler(result)
        }
        removeLaunchItemFromLaunchCoordinator?()
    }

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {}

    let uuid: String = UUID().uuidString

    var handler: LoginHandler?

    weak var safariVC: SFSafariViewController?

    func startLogin(withAuthStore authStore: AuthStore, launchCoordinator: LaunchCoordinator, completionHandler: @escaping LoginHandler) {
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { [weak self] r in
            guard let self else { return }
            switch r {
            case .success:
                let controller = SFSafariViewController(url: self.githubLoginURL)
                controller.modalPresentationStyle = .pageSheet
                UIApplication.shared.topViewController?.present(controller, animated: true, completion: nil)
                let launchItemIdentifier = self.uuid
                launchCoordinator.registerLaunchItem(self, identifier: launchItemIdentifier)
                self.removeLaunchItemFromLaunchCoordinator = { [weak launchCoordinator] in
                    launchCoordinator?.removeLaunchItem(fromIdentifier: launchItemIdentifier)
                }
                self.handler = { [weak authStore, weak self] result in
                    guard let self else { return }
                    if case let .success(user) = result {
                        authStore?.processLoginSuccessUserInfo(user)
                    }
                    completionHandler(result)
                    self.removeLaunchItemFromLaunchCoordinator?()
                }
                self.safariVC = controller
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    var githubLoginURL: URL {
        let env = Env()
        return URL(string: "https://github.com/login/oauth/authorize?client_id=\(env.githubClientId)&redirect_uri=\(env.baseURL)/v1/login/github/callback&state=\(uuid)")!
    }
}
