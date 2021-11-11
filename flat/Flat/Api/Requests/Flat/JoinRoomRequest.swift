//
//  JoinRoomRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct JoinRoomRequest: FlatRequest {
    let info: JoinRoomInfo

    var path: String { "/v1/room/join" }
    var task: Task { .requestJSONEncodable(encodable: ["uuid": info.roomUUID] )}
    let responseType = RoomPlayInfo.self
}
