//
//  StorageMoveFileRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct StorageMoveFileRequest: FlatRequest, Encodable {
    let targetDirectoryPath: String
    let uuids: [String]

    var path: String { "/v2/cloud-storage/move" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: EmptyResponse.Type { EmptyResponse.self }
}
