//
//  RoomStatusUpdateRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/4.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomStatusUpdateRequest: FlatRequest {
    let newStatus: RoomStartStatus
    let roomUUID: String
    
    var path: String { "/v1/room/update-status/\(newStatus.rawValue.lowercased())"}
    var task: Task {
        .requestJSONEncodable(encodable: ["roomUUID": roomUUID])
    }
    let responseType = EmptyResponse.self
}
