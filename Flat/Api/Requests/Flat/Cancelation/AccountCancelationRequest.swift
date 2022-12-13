//
//  AccountCancelationRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AccountCancelationRequest: FlatRequest {
    var path: String { "/v1/user/deleteAccount" }
    var task: Task { .requestPlain }
    let responseType = EmptyResponse.self
}
