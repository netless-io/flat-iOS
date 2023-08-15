//
//  SignUpRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct ResetPasswordRequest: FlatRequest {
    enum ResetType {
        case email(String)
        case phone(String)

        var path: String {
            switch self {
            case .email: return "/v2/reset/email"
            case .phone: return "/v2/reset/phone"
            }
        }

        var jsonPair: (String, String) {
            switch self {
            case .email(let e): return ("email", e)
            case .phone(let p): return ("phone", p)
            }
        }
    }

    let type: ResetType
    let code: String
    let password: String

    var path: String { type.path }
    var task: Task { .requestJSONEncodable(encodable: [type.jsonPair.0: type.jsonPair.1, "password": password, "code": code]) }
    let responseType = EmptyResponse.self
}
