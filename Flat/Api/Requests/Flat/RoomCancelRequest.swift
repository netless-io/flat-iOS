//
//  RoomCancelRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/9.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomCancelRequest: FlatRequest {
    let roomUUID: String
    
    var path: String { "/v1/room/cancel/ordinary" }
    var task: Task { return .requestJSONEncodable(encodable: ["roomUUID": roomUUID])}
    let responseType = EmptyResponse.self
}
