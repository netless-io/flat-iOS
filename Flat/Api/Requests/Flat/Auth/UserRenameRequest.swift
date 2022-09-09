//
//  UserRenameRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct UserRenameRequest: FlatRequest {
    let name: String
    
    var task: Task { .requestJSONEncodable(encodable: ["newUserName": name]) }
    var path: String { "/v2/user/rename" }
    let responseType = EmptyResponse.self
}
