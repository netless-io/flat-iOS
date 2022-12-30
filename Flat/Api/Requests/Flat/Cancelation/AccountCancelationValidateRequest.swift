//
//  AccountCancelationValidateRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AccountCancelationValidateRequest: FlatRequest {
    struct Response: Codable {
        let alreadyJoinedRoomCount: Int
    }

    var path: String { "/v1/user/deleteAccount/validate" }
    let responseType = Response.self
    var task: Task { .requestPlain }
}
