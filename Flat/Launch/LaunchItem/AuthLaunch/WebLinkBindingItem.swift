//
//  GithubBinding.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/11.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import SafariServices

extension LoginType {
    func uuidBindingLink() -> ((String)->URL)? {
        switch self {
        case .github: return Env().githubBindingURLWith(authUUID:)
        case .google: return Env().googleBindingURLWith(authUUID:)
        default: return nil
        }
    }
}

class WebLinkBindingItem: NSObject, LaunchItem {
    private let uuid = UUID().uuidString
    private var unload: (() -> Void)?
    private var handler: (Error?) -> Void
    weak var coordinator: LaunchCoordinator?
    weak var safariVC: SFSafariViewController?
    
    internal init(handler: @escaping ((Error?) -> Void)) {
        self.handler = handler
    }

    deinit {
        unload?()
    }

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {}

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {
        safariVC?.dismiss(animated: true)
        handler(nil)
        unload?()
    }

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        guard url?.absoluteString == "x-agora-flat-client://open" else { return false }
        return true
    }

    func shouldHandle(userActivity: NSUserActivity, scene: UIScene) -> Bool {
        false
    }

    func startBinding(urlMaker: @escaping (String)-> URL, sender: UIView, onCoordinator launchCoordinator: LaunchCoordinator) {
        let req = SetBindingAuthUUIDRequest(uuid: uuid)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                let controller = SFSafariViewController(url: urlMaker(self.uuid))
                controller.delegate = self
                controller.modalPresentationStyle = .pageSheet
                sender.viewController()?.present(controller, animated: true)
                let launchItemIdentifier = self.uuid
                launchCoordinator.registerLaunchItem(self, identifier: launchItemIdentifier)
                self.unload = { [weak launchCoordinator] in
                    launchCoordinator?.removeLaunchItem(fromIdentifier: launchItemIdentifier)
                }
                self.safariVC = controller
            case let .failure(error):
                self.handler(error)
            }
        }
    }
}

extension WebLinkBindingItem: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        handler(localizeStrings("UserCancel"))
    }
}
