//
//  CancelUploadRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/9.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct CancelUploadRequest: FlatRequest {
    let fileUUIDs: [String]
    var path: String { "/v1/cloud-storage/upload/cancel" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUIDs": fileUUIDs])}
    let responseType = EmptyResponse.self
}
