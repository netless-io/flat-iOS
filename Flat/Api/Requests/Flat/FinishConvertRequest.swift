//
//  FinishConvertRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct FinishConvertRequest: FlatRequest {
    let fileUUID: String

    var path: String { "/v2/cloud-storage/convert/finish" }
    var task: Task { .requestJSONEncodable(encodable: ["fileUUID": fileUUID]) }
    let responseType = EmptyResponse.self
}
