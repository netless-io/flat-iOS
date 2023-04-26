//
//  RoomCancelRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/9.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum RoomIdentifier {
    case roomUUID(String)
    case periodRoomUUID(String)
    
    var path: String {
        switch self {
        case .roomUUID:
            return "/v1/room/cancel/ordinary"
        case .periodRoomUUID:
            return "/v1/room/cancel/periodic"
        }
    }
    
    var body: Encodable {
        switch self {
        case .roomUUID(let roomUUID):
            return ["roomUUID": roomUUID]
        case .periodRoomUUID(let periodicUUID):
            return ["periodicUUID": periodicUUID]
        }
    }
}
struct RoomCancelRequest: FlatRequest {
    let roomIdentifier: RoomIdentifier

    var path: String { roomIdentifier.path }
    var task: Task { .requestJSONEncodable(encodable: roomIdentifier.body) }
    let responseType = EmptyResponse.self
}
