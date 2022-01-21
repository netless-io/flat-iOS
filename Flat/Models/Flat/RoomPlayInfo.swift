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
    static func fetchByJoinWith(uuid: String) -> Observable<Self> {
        let request = JoinRoomRequest(info: .init(roomUUID: uuid, inviteCode: ""))
        return ApiProvider.shared.request(fromApi: request)
    }
    
    static func fetchByJoinWith(uuid: String, completion: @escaping ((Result<Self, ApiError>)->Void)) {
        let request = JoinRoomRequest(info: .init(roomUUID: uuid, inviteCode: ""))
        ApiProvider.shared.request(fromApi: request, completionHandler: completion)
    }
}
