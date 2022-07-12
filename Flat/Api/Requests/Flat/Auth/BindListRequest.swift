//
//  BindListRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/11.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct BindingInfo: Codable {
    let wechat: Bool
    let apple: Bool
    let github: Bool
}

struct BindListRequest: FlatRequest {
    var path: String { "/v1/user/binding/list" }
    var task: Task { .requestPlain }
    let responseType = BindingInfo.self
}


