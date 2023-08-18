//
//  UpdatePasswordRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
struct UpdatePasswordRequest: FlatRequest {
    enum PasswordType {
        case new(String)
        case update(password: String, newPassword: String)
        
        var para: Encodable {
            switch self {
            case .new(let newPassword):
                return ["newPassword": newPassword]
            case .update(password: let password, newPassword: let newPassword):
                return ["password": password, "newPassword": newPassword]
            }
        }
    }

    let type: PasswordType

    var path: String { "/v2/user/password" }
    var task: Task { .requestJSONEncodable(encodable: type.para) }
    let responseType = EmptyResponse.self
}
