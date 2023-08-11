//
//  EmailLoginRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/11.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct EmailLoginRequest: FlatRequest {
    let email: String
    let password: String

    var path: String { "/v2/login/email" }
    var task: Task { .requestJSONEncodable(encodable: ["email": email, "password": password]) }
    let responseType = User.self
}
