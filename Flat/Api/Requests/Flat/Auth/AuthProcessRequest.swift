//
//  AuthProcessRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AuthProcessRequest: FlatRequest {
    let uuid: String

    var path: String { "/v1/login/process" }
    var task: Task { .requestJSONEncodable(encodable: ["authUUID": uuid]) }
    let responseType = User.self
}
