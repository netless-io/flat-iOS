//
//  HistoryMessageRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct HistoryMessageRequest: AgoraRequest {
    let messagePath: String
    var path: String { "/dev/v2/project/\(Env().agoraAppId)\(messagePath)" }

    var task: Task { .requestPlain }
    var method: HttpMethod { .get }
    let responseType = AnyKeyDecodable<[AgoraMessage]>.self

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.setAnyCodingKey("messages")
        return decoder
    }
}
