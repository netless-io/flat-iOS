//
//  SetAuthUuidRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RemoveBindingRequest: FlatRequest {
    struct Response: Decodable {
        let token: String
    }
    let type: BindingType
    
    var task: Task { .requestJSONEncodable(encodable: ["target": type.identifierString]) }
    var path: String { "/v1/user/binding/remove" }
    let responseType = Response.self
}
