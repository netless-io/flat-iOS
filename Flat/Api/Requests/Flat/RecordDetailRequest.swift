//
//  RecordDetailRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/24.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct RecordDetailRequest: FlatRequest {
    let uuid: String
    
    var path: String { "/v1/room/record/info" }
    var task: Task { .requestJSONEncodable(encodable: ["roomUUID": uuid]) }
    let responseType = RecordDetailInfo.self
}
