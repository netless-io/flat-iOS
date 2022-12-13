//
//  SMSRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct SMSRequest: FlatRequest {
    enum Scenario {
        case login
        case bind

        var path: String {
            switch self {
            case .login:
                return "/v1/login/phone/sendMessage"
            case .bind:
                return "/v1/user/bindingPhone/sendMessage"
            }
        }
    }

    let scenario: Scenario
    let phone: String

    var path: String { scenario.path }
    var task: Task { .requestJSONEncodable(encodable: ["phone": phone]) }
    let responseType = EmptyResponse.self
}
