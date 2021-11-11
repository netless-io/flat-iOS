//
//  RoomHistoryRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomHistoryRequest: FlatRequest {
    let page: Int
    
    var path: String { "/v1/room/list/history" }
    var task: Task { .requestURLEncodable(parameters: ["page": page])}
    let responseType = [RoomListInfo].self
}
