//
//  UpdatePasswordRequest.swift
//  flat
//
//  Created by xuyunshi on 2023/08/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
struct UpdatePasswordRequest: FlatRequest {
    let password: String
    let newPassword: String

    var path: String { "/v2/user/password" }
    var task: Task { .requestJSONEncodable(encodable: ["password": password, "newPassword": newPassword]) }
    let responseType = EmptyResponse.self
}
