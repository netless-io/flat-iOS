//
//  MessageCensorRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/2/9.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct MessageCensorRequest: FlatRequest {
    struct Response: Decodable {
        let valid: Bool
    }

    let text: String

    var path: String { "/v1/agora/rtm/censor" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: ["text": text]) }
    let responseType = Response.self
}
