//
//  SMSRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct SMSRequest: FlatRequest {
    enum SMSLanguageType: String {
        case zh
        case en
    }
    enum Scenario {
        case login(phone: String)
        case bind(phone: String)
        case emailRegister(email: String, language: SMSLanguageType)

        var path: String {
            switch self {
            case .login:
                return "/v1/login/phone/sendMessage"
            case .bind:
                return "/v1/user/bindingPhone/sendMessage"
            case .emailRegister:
                return "/v2/register/email/send-message"
            }
        }
        
        var encodableResult: Encodable {
            switch self {
            case .login(phone: let phone): return ["phone": phone]
            case .bind(phone: let phone): return ["phone": phone]
            case .emailRegister(email: let email, language: let l): return ["email": email, "language": l.rawValue]
            }
        }
    }

    let scenario: Scenario
    var path: String { scenario.path }
    var task: Task { .requestJSONEncodable(encodable: scenario.encodableResult) }
    let responseType = EmptyResponse.self
}
