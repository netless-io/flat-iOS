//
//  RoomOperation.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/29.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import UIKit

let roomRemovedNotification = "roomRemovedNotification"

extension RoomBasicInfo {
    func roomActions(rootController: UIViewController) -> [Action] {
        let room = self
        func performRemoveReqeust() {
            rootController.showActivityIndicator()
            let request: RoomCancelRequest
            if let periodicUUID, !periodicUUID.isEmpty {
                request = RoomCancelRequest(roomIdentifier: .periodRoomUUID(periodicUUID))
            } else {
                request = RoomCancelRequest(roomIdentifier: .roomUUID(roomUUID))
            }
            ApiProvider.shared.request(fromApi: request) { result in
                rootController.stopActivityIndicator()
                switch result {
                case .success:
                    NotificationCenter.default.post(name: .init(rawValue: roomRemovedNotification), object: nil, userInfo: ["roomUUID": room.roomUUID])
                case let .failure(error):
                    rootController.toast(error.localizedDescription)
                }
            }
        }

        let cancelAction = Action(title: localizeStrings("Cancel Room"),
                                  style: .destructive) { [weak rootController] _ in
            rootController?.showDeleteAlertWith(message: localizeStrings("Cancel Room Verbose")) {
                performRemoveReqeust()
            }
        }
        let removeAction = Action(title: localizeStrings("Remove From List"),
                                  image: UIImage(named: "delete_room"),
                                  style: .destructive) { [weak rootController] _ in
            rootController?.showCheckAlert(message: localizeStrings("Remove Room Verbose")) {
                performRemoveReqeust()
            }
        }
        switch room.roomStatus {
        case .Idle:
            if room.isOwner {
                return [cancelAction]
            }
            return [removeAction]
        case .Started, .Paused:
            if room.isOwner { return [] }
            return [removeAction, .cancel]
        default:
            return []
        }
    }
}
