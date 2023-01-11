//
//  JoinRoomLaunchItem.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/3.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift

class JoinRoomLaunchItem: LaunchItem {
    var uuid: String!
    var scene: UIWindowScene?

    var disposeBag = RxSwift.DisposeBag()

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        self.scene = scene as? UIWindowScene
        if let url {
            if url.scheme == "x-agora-flat-client",
               url.host == "joinRoom",
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
                UIApplication.shared.topWith(windowScene: scene as? UIWindowScene)?.showAlertWith(message: roomId)
                return true
            }
        }
        return false
    }

    fileprivate func getUniversalLinkRoomUUID(_ url: URL) -> String? {
        if url.pathComponents.contains("join"),
           let roomUUID = url.pathComponents.last,
           roomUUID.isNotEmptyOrAllSpacing
        {
            return roomUUID
        }
        return nil
    }

    func shouldHandle(userActivity: NSUserActivity, scene _: UIScene) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        if let roomId = getUniversalLinkRoomUUID(url) {
            uuid = roomId
            return true
        }
        return false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user: User) {
        ClassroomCoordinator.shared.enterClassroom(uuid: uuid,
                                                   periodUUID: nil,
                                                   basicInfo: nil,
                                                   sender: scene)
    }
}
