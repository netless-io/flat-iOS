//
//  RenameFileRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct RenameFileRequest: FlatRequest {
    let fileName: String
    let fileUUID: String
    let external: Bool
    var path: String {
        external ? "/v1/cloud-storage/url-cloud/rename" : "/v1/cloud-storage/alibaba-cloud/rename"
    }
    var task: Task { .requestJSONEncodable(encodable: ["fileName": fileName, "fileUUID": fileUUID])}
    let responseType = EmptyResponse.self
}
