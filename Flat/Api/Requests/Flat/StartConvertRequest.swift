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

struct StartConvertRequest: FlatRequest, Encodable {
    let fileUUID: String
    let isWhiteboardProjector: Bool
    
    var path: String { "/v1/cloud-storage/convert/start" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: StartConvertResponse.Type { StartConvertResponse.self }
}
