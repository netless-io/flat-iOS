//
//  TempPhotoStartRequest.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

struct TempPhotoStartRequest: FlatRequest, Codable {
    let fileName: String
    let fileSize: Int
    var path: String { "/v2/temp-photo/upload/start" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: UploadInfo.Type { UploadInfo.self }
}
