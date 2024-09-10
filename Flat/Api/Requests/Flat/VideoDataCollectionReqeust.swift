//
//  VideoDataCollectionToggleReqeust.swift
//  Flat
//
//  Created by xuyunshi on 2024/9/10.
//  Copyright © 2024 agora.io. All rights reserved.
//

import Foundation

struct VideoDataCollectionReqeust: FlatRequest {
    struct Response: Decodable {
        let isAgree: Bool
    }
    var method: HttpMethod { .post }
    var task: Task { .requestPlain }
    var path: String { "/v1/user/agreement/get" }
    let responseType = Response.self
}

struct VideoDataCollectionToggleReqeust: FlatRequest {
    let agree: Bool
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: ["is_agree_collect_data": agree]) }
    var path: String { "/v1/user/agreement/set" }
    let responseType = EmptyResponse.self
}
