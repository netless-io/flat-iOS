//
//  GithubLogin.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import SafariServices
import UIKit

class WebLinkLoginItem: NSObject, LaunchItem {
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

    func startLogin(withAuthStore authStore: AuthStore,
                    launchCoordinator: LaunchCoordinator,
                    sender: UIButton,
                    urlMaker: ((String) -> URL),
                    completionHandler: @escaping LoginHandler) {
        let url = urlMaker(uuid)
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { [weak self] r in
            guard let self else { return }
            switch r {
            case .success:
                let controller = SFSafariViewController(url: url)
                controller.delegate = self
                controller.modalPresentationStyle = .fullScreen
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
}

extension WebLinkLoginItem: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        handler?(.failure(""))
    }
}
