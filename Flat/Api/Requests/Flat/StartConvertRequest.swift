//
//  StartConvertRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct StartConvertRequest: FlatRequest, Encodable {
    let fileUUID: String

    var path: String { "/v2/cloud-storage/convert/start" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: StorageFileModel.Payload.Type { StorageFileModel.Payload.self }
}
