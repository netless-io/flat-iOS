//
//  BindingPhoneRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct BindingPhoneRequest: FlatRequest {
    let phone: String
    let code: String
    
    var path: String { "/v1/user/bindingPhone" }
    var task: Task { .requestJSONEncodable(encodable: ["phone": phone, "code": code]) }
    let responseType = EmptyResponse.self
}

