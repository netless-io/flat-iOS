//
//  StartConvertRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct StartConvertResponse: Decodable {
    let taskToken: String
    let taskUUID: String
}

struct StartConvertRequest: FlatRequest {
    let fileUUID: String
    
    var path: String { "/v1/cloud-storage/convert/start" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID]) }
    let responseType = StartConvertResponse.self
}
