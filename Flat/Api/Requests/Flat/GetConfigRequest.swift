//
//  GetConfigRequest.swift
//  Flat
//
//  Created by xuyunshi on 2024/2/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct FlatConfigResult: Codable {
    struct ServerConfig: Codable {
        fileprivate let joinEarly: TimeInterval
        var joinEarlySeconds: TimeInterval {
            joinEarly * 60
        }
    }
    let server: ServerConfig
}
struct GetConfigRequest: FlatRequest {
    var path: String { "/v2/region/configs" }
    var method: HttpMethod { .get }
    var task: Task { .requestPlain }
    let responseType = FlatConfigResult.self
}
