//
//  UpdateRecordEndTimeRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct UpdateRecordEndTimeRequest: FlatRequest {
    let roomUUID: String
    var path: String { "/v1/room/record/update-end-time" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: ["roomUUID": roomUUID]) }
    let responseType = EmptyResponse.self
}
