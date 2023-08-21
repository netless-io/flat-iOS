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
    var task: Task { .requestJSONEncodable(encodable: ["uuid": info.periodicUUID ?? info.roomUUID]) }
    var customBaseURL: String? {
        for server in Env().servers {
            if info.roomUUID.hasPrefix(server.classroomUUIDPrefix) {
                return server.baseURL
            }
            if info.roomUUID.hasPrefix(server.classroomInviteCode.description) {
                return server.baseURL
            }
        }
        return nil
    }
    let responseType = RoomPlayInfo.self
}
