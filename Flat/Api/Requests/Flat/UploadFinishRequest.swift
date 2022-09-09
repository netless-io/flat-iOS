//
//  UploadFinishRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadFinishRequest: FlatRequest, Encodable {
    let fileUUID: String
    var path: String { "/v2/cloud-storage/upload/finish" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: EmptyResponse.Type { EmptyResponse.self }
}
