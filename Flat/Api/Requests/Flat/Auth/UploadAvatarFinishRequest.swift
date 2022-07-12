//
//  UploadFinishRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadAvatarFinishRequest: FlatRequest {
    struct Response: Decodable {
        let avatarURL: URL
    }
    let fileUUID: String
    let region: Region
    var path: String { "/v1/user/upload-avatar/finish" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID, "region": region.rawValue]) }
    let responseType = Response.self
}
