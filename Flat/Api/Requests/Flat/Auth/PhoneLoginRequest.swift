//
//  PhoneLoginRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/11.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct PhoneLoginRequest: FlatRequest {
    let phone: String
    let password: String

    var path: String { "/v2/login/phone" }
    var task: Task { .requestJSONEncodable(encodable: ["phone": phone, "password": password]) }
    let responseType = User.self
}
