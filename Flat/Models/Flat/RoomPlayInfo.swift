//
//  RoomPlayInfo.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift

struct RoomPlayInfo: Codable {
    struct BillingInfo: Codable {
        // Time limit.
        let limit: Int
    }
    let billing: BillingInfo
    let roomType: ClassRoomType
    let roomUUID: String
    let ownerUUID: String
    let whiteboardRoomToken: String
    let whiteboardRoomUUID: String
    let rtcUID: UInt
    let rtcToken: String
    let rtcShareScreen: ShareScreenInfo
    let rtmToken: String
    let region: String

    var rtmChannelId: String { roomUUID }
}

extension RoomPlayInfo {
    var userInfo: User? {
        AuthStore.shared.user
    }

    var rtmUID: String {
        userInfo?.userUUID ?? ""
    }
}

extension RoomPlayInfo {
    static func fetchByJoinWith(uuid: String, periodicUUID: String?) -> Observable<Self> {
        let request = JoinRoomRequest(info: .init(roomUUID: uuid, periodicUUID: periodicUUID, inviteCode: ""))
        return ApiProvider.shared.request(fromApi: request)
    }

    static func fetchByJoinWith(uuid: String, periodicUUID: String?, completion: @escaping ((Result<Self, Error>) -> Void)) {
        let request = JoinRoomRequest(info: .init(roomUUID: uuid, periodicUUID: periodicUUID, inviteCode: ""))
        ApiProvider.shared.request(fromApi: request, completionHandler: completion)
    }
}
