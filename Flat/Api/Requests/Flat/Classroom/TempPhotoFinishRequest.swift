//
//  TempPhotoStartRequest.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

struct TempPhotoFinishRequest: FlatRequest {
    let fileUUID: String
    var path: String { "/v2/temp-photo/upload/finish" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID]) }
    let responseType = EmptyResponse.self
}
