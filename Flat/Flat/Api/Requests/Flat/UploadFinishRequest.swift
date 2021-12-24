//
//  UploadFinishRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadFinishRequest: FlatRequest {
    let fileUUID: String
    let region: Region
    var path: String { "/v1/cloud-storage/alibaba-cloud/upload/finish" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID, "region": region.rawValue])}
    let responseType = EmptyResponse.self
}
