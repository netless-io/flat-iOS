//
//  SMSRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct SMSRequest: FlatRequest {
    let phone: String
    
    var path: String { "/v1/login/phone/sendMessage" }
    var task: Task { .requestJSONEncodable(encodable: ["phone": phone]) }
    let responseType = EmptyResponse.self
}

