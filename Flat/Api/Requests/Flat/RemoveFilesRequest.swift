//
//  RemoveFilesRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct RemoveFilesRequest: FlatRequest {
    let fileUUIDs: [String]
    var path: String { "/v2/cloud-storage/delete" }
    var task: Task { .requestJSONEncodable(encodable: ["uuids": fileUUIDs]) }
    let responseType = EmptyResponse.self
}
