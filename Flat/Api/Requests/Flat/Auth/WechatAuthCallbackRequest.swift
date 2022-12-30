//
//  WechatAuthCallbackRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/2.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct WechatCallBackRequest: FlatRequest {
    let uuid: String
    let code: String

    var path: String { "/v1/login/weChat/mobile/callback" }
    var method: HttpMethod { .get }
    var task: Task { .requestURLEncodable(parameters: ["state": uuid, "code": code]) }
    let responseType = User.self
}
