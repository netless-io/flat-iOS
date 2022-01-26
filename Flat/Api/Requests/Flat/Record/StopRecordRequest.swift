//
//  StopRecordRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct StopResponse: Codable {
    struct ServerResponse: Codable {
        let fileListMode: String
        let fileList: String
        let uploadingStatus: String
    }
    let resourceId: String
    let sid: String
    let serverResponse: ServerResponse
}

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
    var responseType: StopResponse.Type { StopResponse.self }
}
