//
//  CancelRoomHistoryRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/2/9.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct CancelRoomHistoryRequest: FlatRequest {
    let roomUUID: String

    var path: String { "/v1/room/cancel/history" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: ["roomUUID": roomUUID]) }
    let responseType = EmptyResponse.self
}
