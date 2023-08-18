//
//  BindListRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/11.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct BindingMetaInfo: Decodable {
    let phone: String
    let wechat: String
    let apple: String
    let github: String
    let email: String
    let google: String
}

struct BindingInfo: Decodable {
    let phone: Bool
    let wechat: Bool
    let apple: Bool
    let github: Bool
    let email: Bool
    let google: Bool
    let meta: BindingMetaInfo
}

struct BindListRequest: FlatRequest {
    var path: String { "/v1/user/binding/list" }
    var task: Task { .requestPlain }
    let responseType = BindingInfo.self
}
