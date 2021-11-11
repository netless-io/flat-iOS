//
//  RoomInfoRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomInfoRequest: FlatRequest {
    let uuid: String
    
    var path: String { "/v1/room/info/ordinary" }
    var task: Task { .requestJSONEncodable(encodable: ["roomUUID": uuid]) }
    let responseType = RawRoomInfo.self
}
