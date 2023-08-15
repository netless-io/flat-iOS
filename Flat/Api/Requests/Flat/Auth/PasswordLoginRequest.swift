//
//  PasswordLoginRequest.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

struct PasswordLoginRequest: FlatRequest {
    enum AccountType {
        case phone(String)
        case email(String)
        
        var path: String {
            switch self {
            case .phone: return "/v2/login/phone"
            case .email: return "/v2/login/email"
            }
        }
        
        var accountPair: (String, String) {
            switch self {
            case .phone(let p): return ("phone", p)
            case .email(let e): return ("email", e)
            }
        }
    }
    let account: AccountType
    let password: String

    var path: String { account.path }
    var task: Task { .requestJSONEncodable(encodable: [account.accountPair.0: account.accountPair.1, "password": password]) }
    let responseType = User.self
}
