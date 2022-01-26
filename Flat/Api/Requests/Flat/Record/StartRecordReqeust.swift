//
//  StartRecordRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

enum MixedVideoLayout: Int, Codable {
    case float = 0
    case adapt = 1
    case vertical = 2
    case custom = 3
}

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
    struct LayoutConfig: Codable {
        let x_axis: Float
        let y_axis: Float
        let width: Float
        let height: Float
    }
    
    struct AgoraParams: Codable {
        let resourceid: String
        let mode: AgoraRecordMode
    }
    
    struct BackgroundConfig: Codable {
        let uid: String
        let image_url: String
    }
    
    struct TranscodingConfig: Codable {
        let width: Int
        let height: Int
        let fps: Int
        let bitrate: Int
        let mixedVideoLayout: MixedVideoLayout
        let backgroundColor: String // #000000
        let defaultUserBackgroundImage: String  //https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/cloud-recording/default-avatar.jpg"
        let backgroundConfig: [BackgroundConfig]
        let layoutConfig: [LayoutConfig]
    }
    
    struct RecordingConfig: Codable {
        let channelType: Int
        let maxIdleTime: Int
        ///（选填）Number 类型，预估的订阅人数峰值。
        let subscribeUidGroup: Int
        let transcodingConfig: TranscodingConfig
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
