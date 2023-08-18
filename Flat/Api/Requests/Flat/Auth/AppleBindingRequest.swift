//
//  AppleBindingRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AppleBindingRequest: FlatRequest {
    let jwtToken: String
    let nickname: String?

    var task: Task {
        if let nickname {
            return .requestJSONEncodable(encodable: ["jwtToken": jwtToken, "nickname": nickname])
        } else {
            return .requestJSONEncodable(encodable: ["jwtToken": jwtToken])
        }
    }

    var path: String { "/v1/user/binding/platform/apple" }
    let responseType = EmptyResponse.self
}
