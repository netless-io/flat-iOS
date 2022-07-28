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
    let region: FlatRegion
    let isWhiteboardProjector: Bool
    var path: String { "/v1/cloud-storage/alibaba-cloud/upload/finish" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: EmptyResponse.Type { EmptyResponse.self }
}
