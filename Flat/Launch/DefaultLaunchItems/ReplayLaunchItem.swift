//
//  ReplayLaunchItem.swift
//  Flat
//
//  Created by xuyunshi on 2023/07/08.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift

class ReplayLaunchItem: LaunchItem {
    var uuid: String!
    var scene: UIWindowScene?

    var disposeBag = RxSwift.DisposeBag()

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        self.scene = scene as? UIWindowScene
        if let url {
            if url.scheme == "x-agora-flat-client",
               url.host == "replayRoom",
               let roomId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
               .queryItems?
               .first(where: { $0.name == "roomUUID" })?
               .value,
               roomId.isNotEmptyOrAllSpacing
            {
                uuid = roomId
                return true
            } else if let roomId = getUniversalLinkRoomUUID(url) {
                uuid = roomId
                return true
            }
        }
        return false
    }

    fileprivate func getUniversalLinkRoomUUID(_ url: URL) -> String? {
        // Url style:
        // host/replay/{roomType}/{roomUUID}/{ownerUUID}
        if url.pathComponents.contains("replay"),
           url.pathComponents.count >= 5,
           url.pathComponents[3].isNotEmptyOrAllSpacing
        {
            return url.pathComponents[3]
        }
        return nil
    }

    func shouldHandle(userActivity: NSUserActivity, scene: UIScene) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        self.scene = scene as? UIWindowScene
        if let roomId = getUniversalLinkRoomUUID(url) {
            uuid = roomId
            return true
        }
        return false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func afterLoginSuccessImplementation(withLaunchCoordinator coordinator: LaunchCoordinator, user: User) {
        guard let controller = scene?.viewController() else { return }
        controller.showActivityIndicator()
        ApiProvider.shared.request(fromApi: RecordDetailRequest(uuid: uuid)) { [weak controller] result in
            guard let controller else { return }
            controller.stopActivityIndicator()
            switch result {
            case let .success(recordInfo):
                let viewModel = MixReplayViewModel(recordDetail: recordInfo)
                let vc = MixReplayViewController(viewModel: viewModel)
                controller.mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            case let .failure(error):
                controller.toast(error.localizedDescription)
            }
        }
    }
}
