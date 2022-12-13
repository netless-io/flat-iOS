//
//  StorageCreateDirectoryRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct StorageCreateDirectoryRequest: FlatRequest, Encodable {
    let parentDirectoryPath: String
    let directoryName: String

    var path: String { "/v2/cloud-storage/create-directory" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: EmptyResponse.Type { EmptyResponse.self }
}
