//
//  StopRecordRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct StopRecordRequest: FlatRequest, Encodable {
    struct AgoraParams: Codable {
        let resourceid: String
        let sid: String
        let mode: AgoraRecordMode
    }
    
    var path: String { "/v1/room/record/agora/stopped" }
    let roomUUID: String
    let agoraParams: AgoraParams
    
    var task: Task { .requestJSONEncodable(encodable: self) }
    var method: HttpMethod { .post }
    var responseType: EmptyResponse.Type { EmptyResponse.self }
}
