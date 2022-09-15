//
//  StartRecordRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

enum AgoraRecordMode: String, Codable {
    case individual
    case mix
    case web
}

struct StartRecordResponse: Codable {
    let resourceId: String
    let sid: String
}

struct StartRecordRequest: FlatRequest, Encodable {
    struct AgoraParams: Codable {
        let resourceid: String
        let mode: AgoraRecordMode
    }
    
    enum StreamMode: String, Codable {
        case `default` = "default"
        case standard = "standard"
        case original = "original"
    }
    
    enum StreamType: Int, Codable {
        case hd = 0
        case small
    }
    
    enum ChannelType: Int, Codable {
        case communication = 0
        case boardcast
    }
    
    struct RecordingConfig: Codable {
        let channelType: ChannelType
        let maxIdleTime: Int
        ///（选填）Number 类型，预估的订阅人数峰值。
        let subscribeUidGroup: Int
        let streamMode: StreamMode
        let videoStreamType: StreamType
    }
    
    struct ClientRequest: Codable {
        let recordingConfig: RecordingConfig
    }
    
    struct AgoraData: Codable {
        let clientRequest: ClientRequest
    }
    
    var path: String {
        "/v1/room/record/agora/started"
    }
    let roomUUID: String
    let agoraData: AgoraData
    let agoraParams: AgoraParams
    
    var task: Task { .requestJSONEncodable(encodable: self) }
    var method: HttpMethod { .post }
    var responseType: StartRecordResponse.Type { StartRecordResponse.self }
}
