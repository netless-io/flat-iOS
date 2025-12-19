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
        case login(phone: String, captchaVerifyParam: String)
        case bind(phone: String, captchaVerifyParam: String)
        case rebind(phone: String, captchaVerifyParam: String)
        case bindEmail(String)
        case resetPhone(String, captchaVerifyParam: String)
        case resetEmail(String, language: SMSLanguageType)
        case emailRegister(email: String, language: SMSLanguageType)
        case phoneRegister(phone: String, captchaVerifyParam: String)

        var path: String {
            switch self {
            case .rebind:
                return "/v2/user/rebind-phone/send-message/captcha"
            case .bindEmail:
                return "/v1/user/bindingEmail/sendMessage"
            case .login:
                return "/v1/login/phone/sendMessage/captcha"
            case .bind:
                return "/v1/user/bindingPhone/sendMessage/captcha"
            case .resetPhone:
                return "/v2/reset/phone/send-message/captcha"
            case .resetEmail:
                return "/v2/reset/email/send-message"
            case .emailRegister:
                return "/v2/register/email/send-message"
            case .phoneRegister:
                return "/v2/register/phone/send-message/captcha"
            }
        }

        var encodableResult: Encodable {
            switch self {
            case .rebind(phone: let phone, captchaVerifyParam: let captchaVerifyParam):
                return ["phone": phone, "captchaVerifyParam": captchaVerifyParam]
            case .bindEmail(let email): return ["email": email]
            case .login(phone: let phone, captchaVerifyParam: let captchaVerifyParam):
                return ["phone": phone, "captchaVerifyParam": captchaVerifyParam]
            case .bind(phone: let phone, captchaVerifyParam: let captchaVerifyParam):
                return ["phone": phone, "captchaVerifyParam": captchaVerifyParam]
            case .resetPhone(let phone, captchaVerifyParam: let captchaVerifyParam):
                return ["phone": phone, "captchaVerifyParam": captchaVerifyParam]
            case .resetEmail(let email, language: let l): return ["email": email, "language": l.rawValue]
            case .emailRegister(email: let email, language: let l): return ["email": email, "language": l.rawValue]
            case .phoneRegister(phone: let phone, captchaVerifyParam: let captchaVerifyParam):
                return ["phone": phone, "captchaVerifyParam": captchaVerifyParam]
            }
        }
    }

    let scenario: Scenario
    var path: String { scenario.path }
    var task: Task { .requestJSONEncodable(encodable: scenario.encodableResult) }
    let responseType = EmptyResponse.self
}
