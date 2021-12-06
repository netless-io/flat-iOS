//
//  WechatLogin.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/2.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class WechatLogin: NSObject, LaunchItem {
    var handler: LoginHandler?
    weak var authStore: AuthStore?
    var removeLaunchItemFromLaunchCoordinator: (()->Void)?
    
    func shouldHandle(userActivity: NSUserActivity) -> Bool {
        if WXApi.handleOpenUniversalLink(userActivity, delegate: self) {
            return true
        }
        return false
    }
    
    deinit {
        print(self, "deinit")
        removeLaunchItemFromLaunchCoordinator?()
    }
    
    func shouldHandle(url: URL?) -> Bool { false }
    
    let uuid: String = UUID().uuidString
    
    func afterLoginSuccessImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator, user: User) { }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator) {}
    
    func startLogin(withAuthstore authStore: AuthStore, launchCoordinator: LaunchCoordinator, completionHandler: @escaping LoginHandler) {
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { [weak self] r in
            guard let self = self  else {
                completionHandler(.failure(.message(message: "self not exist")))
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
                    guard let self = self else { return }
                    if case .success(let user) = result {
                        authStore?.processLoginSuccessUserInfo(user)
                    }
                    completionHandler(result)
                    self.removeLaunchItemFromLaunchCoordinator?()
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}

extension WechatLogin: WXApiDelegate {
    func onReq(_ req: BaseReq) {}
    
    func onResp(_ resp: BaseResp) {
        guard let handler = self.handler else { return }
        guard resp.isKind(of: SendAuthResp.self) else { return }
        guard resp.errCode == 0, let newResp = resp as? SendAuthResp, let code = newResp.code else {
            handler(.failure(.message(message: resp.errStr)))
            return
        }
        let req = WechatCallBackRequest(uuid: uuid, code: code)
        ApiProvider.shared.request(fromApi: req, completionHandler: handler)
    }
}
