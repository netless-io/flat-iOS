//
//  PrepareUploadRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct PrepareUploadRequest: FlatRequest, Codable {
    let fileName: String
    let fileSize: Int
    let targetDirectoryPath: String
    var path: String { "/v2/cloud-storage/upload/start" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: UploadInfo.Type { UploadInfo.self }
}
