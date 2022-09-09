//
//  UploadFinishRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadAvatarFinishRequest: FlatRequest {
    let fileUUID: String
    var path: String { "/v2/user/upload-avatar/finish" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID]) }
    let responseType = EmptyResponse.self
}
