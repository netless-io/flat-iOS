//
//  TempLogRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/28.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct TempLogRequest: FlatRequest {
    let roomUUID: String?
    let log: String
    
    var logMessage: String {
        let roomUUIDStr: String
        if let roomUUID = roomUUID {
            roomUUIDStr = "roomUUID: \(roomUUID) , "
        } else {
            roomUUIDStr = ""
        }
        
        return "uuid: \(AuthStore.shared.user?.userUUID ?? "") , " + roomUUIDStr + log
    }
    
    var path: String { "/v1/log" }
    var method: HttpMethod { .post }
    var task: Task { .requestJSONEncodable(encodable: ["type": "iOS", "message": logMessage]) }
    let responseType = EmptyResponse.self
}
