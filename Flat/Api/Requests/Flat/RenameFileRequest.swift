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
    var path: String { "/v2/cloud-storage/rename" }
    var task: Task { .requestJSONEncodable(encodable: ["newName": fileName, "fileUUID": fileUUID]) }
    let responseType = EmptyResponse.self
}
