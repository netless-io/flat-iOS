//
//  WechatLogin.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/2.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class WeChatLogin: NSObject, LaunchItem {
    var handler: LoginHandler?
    weak var authStore: AuthStore?
    var removeLaunchItemFromLaunchCoordinator: (() -> Void)?

    func shouldHandle(userActivity: NSUserActivity, scene: UIScene) -> Bool {
        if WXApi.handleOpenUniversalLink(userActivity, delegate: self) {
            return true
        }
        return false
    }

    deinit {
        globalLogger.trace("\(self), deinit")
    }

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        guard let url else { return false }
        if WXApi.handleOpen(url, delegate: self) {
            return true
        }
        return false
    }

    let uuid: String = UUID().uuidString

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {}

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func startLogin(withAuthStore authStore: AuthStore, launchCoordinator: LaunchCoordinator, completionHandler: @escaping LoginHandler) {
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { [weak self] r in
            guard let self else {
                completionHandler(.failure("self not exist"))
                return
            }
            switch r {
            case .success:
                let request = SendAuthReq()
                request.scope = "snsapi_userinfo"
                request.state = "flat"
                WXApi.send(request)
                let launchItemIdentifier = self.uuid
                launchCoordinator.registerLaunchItem(self, identifier: launchItemIdentifier)
                self.removeLaunchItemFromLaunchCoordinator = { [weak launchCoordinator] in
                    launchCoordinator?.removeLaunchItem(fromIdentifier: launchItemIdentifier)
                }
                self.authStore = authStore
                self.handler = { [weak authStore, weak self] result in
                    guard let self else { return }
                    if case let .success(user) = result {
                        authStore?.processLoginSuccessUserInfo(user)
                    }
                    completionHandler(result)
                    self.removeLaunchItemFromLaunchCoordinator?()
                }
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
}

extension WeChatLogin: WXApiDelegate {
    func onReq(_: BaseReq) {}

    func onResp(_ resp: BaseResp) {
        removeLaunchItemFromLaunchCoordinator?()
        guard let handler else { return }
        guard resp.isKind(of: SendAuthResp.self) else { return }
        guard resp.errCode == 0, let newResp = resp as? SendAuthResp, let code = newResp.code else {
            handler(.failure(resp.errStr))
            return
        }
        let req = WechatCallBackRequest(uuid: uuid, code: code)
        ApiProvider.shared.request(fromApi: req, completionHandler: handler)
    }
}
