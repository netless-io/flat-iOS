//
//  PrepareUploadRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct PrepareAvatarUploadRequest: FlatRequest, Codable {
    let fileName: String
    let fileSize: Int
    var region: FlatRegion
    var path: String { "/v1/user/upload-avatar/start" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: UploadInfo.Type { UploadInfo.self }
}
