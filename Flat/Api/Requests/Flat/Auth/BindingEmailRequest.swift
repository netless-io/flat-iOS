//
//  BindingEmailRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct BindingEmailRequest: FlatRequest {
    let email: String
    let code: String

    var path: String { "/v1/user/binding/platform/email" }
    var task: Task { .requestJSONEncodable(encodable: ["email": email, "code": code]) }
    let responseType = EmptyResponse.self
}
