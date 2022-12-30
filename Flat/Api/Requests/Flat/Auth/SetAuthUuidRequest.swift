//
//  SetAuthUuidRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct SetAuthUuidRequest: FlatRequest {
    let uuid: String

    var task: Task { .requestJSONEncodable(encodable: ["authUUID": uuid]) }
    var path: String { "/v1/login/set-auth-uuid" }
    let responseType = EmptyResponse.self
}
