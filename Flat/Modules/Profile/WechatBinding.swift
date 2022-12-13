//
//  BindItem.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/11.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift

class WechatBinding: NSObject, LaunchItem {
    internal init(handler: @escaping ((Error?) -> Void)) {
        self.handler = handler
    }

    var removeLaunchItemFromLaunchCoordinator: (() -> Void)?

    let uuid = UUID().uuidString
    var handler: (Error?) -> Void
    weak var coordinator: LaunchCoordinator?

    deinit {
        removeLaunchItemFromLaunchCoordinator?()
    }

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {}

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func shouldHandle(url: URL?) -> Bool {
        guard let url else { return false }
        if WXApi.handleOpen(url, delegate: self) {
            return true
        }
        return false
    }

    func shouldHandle(userActivity: NSUserActivity) -> Bool {
        if WXApi.handleOpenUniversalLink(userActivity, delegate: self) {
            return true
        }
        return false
    }

    func startBinding(onCoordinator coordinator: LaunchCoordinator) {
        let req = SetBindingAuthUUIDRequest(uuid: uuid)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                let request = SendAuthReq()
                request.scope = "snsapi_userinfo"
                request.state = "flat"
                WXApi.send(request)
                let id = self.uuid
                coordinator.registerLaunchItem(self, identifier: id)
                self.removeLaunchItemFromLaunchCoordinator = { [weak coordinator] in
                    coordinator?.removeLaunchItem(fromIdentifier: id)
                }
            case let .failure(error):
                self.handler(error)
            }
        }
    }
}

extension WechatBinding: WXApiDelegate {
    func onReq(_: BaseReq) {}

    func onResp(_ resp: BaseResp) {
        removeLaunchItemFromLaunchCoordinator?()
        guard resp.isKind(of: SendAuthResp.self) else { return }
        guard resp.errCode == 0, let newResp = resp as? SendAuthResp, let code = newResp.code else {
            handler(resp.errStr)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let request = WechatBindingRequest(uuid: self.uuid, code: code)
            ApiProvider.shared.request(fromApi: request) { result in
                switch result {
                case let .failure(error):
                    self.handler(error)
                case .success:
                    self.handler(nil)
                }
            }
        }
    }
}
