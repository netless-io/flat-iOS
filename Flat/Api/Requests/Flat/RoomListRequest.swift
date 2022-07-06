//
//  RoomListRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomListRequest: FlatRequest {
    let page: Int
    
    var path: String { "/v1/room/list/all" }
    var task: Task { .requestURLEncodable(parameters: ["page": page])}
    let responseType = [RoomBasicInfo].self
}
