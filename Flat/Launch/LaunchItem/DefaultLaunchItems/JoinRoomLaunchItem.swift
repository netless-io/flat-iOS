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
        if let roomUuid = url?.absoluteString.getRoomUuidFromLink() {
            uuid = roomUuid
            return true
        }
        return false
    }

    func shouldHandle(userActivity: NSUserActivity, scene: UIScene) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        self.scene = scene as? UIWindowScene
        if let roomId = url.absoluteString.getRoomUuidFromLink() {
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
