//
//  SetAuthUuidRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct AppleLoginRequest: FlatRequest {
    let jwtToken: String
    let nickname: String?
    
    var task: Task {
        if let nickname = nickname {
            return .requestJSONEncodable(encodable: ["jwtToken": jwtToken, "nickname": nickname])
        } else {
            return .requestJSONEncodable(encodable: ["jwtToken": jwtToken])
        }
    }
    var path: String { "/v1/login/apple/jwt" }
    let responseType = User.self
}
