//
//  SetAuthUuidRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct WechatBindingRequest: FlatRequest {
    let uuid: String
    let code: String
    
    var method: HttpMethod { .get }
    var task: Task { .requestURLEncodable(parameters: ["state": uuid, "code": code]) }
    var path: String { "/v1/user/binding/platform/wechat/mobile" }
    let responseType = EmptyResponse.self
}
