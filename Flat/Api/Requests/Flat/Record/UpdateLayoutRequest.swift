//
//  UpdateLayoutReqeust.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct UpdateLayoutResponse: Codable {
    let resourceId: String
    let sid: String
}

struct UpdateLayoutRequest: FlatRequest, Encodable {
    struct LayoutConfig: Codable {
        let x_axis: Float
        let y_axis: Float
        let width: Float
        let height: Float
    }
    
    struct AgoraParams: Codable {
        let resourceid: String
        let mode: AgoraRecordMode
        let sid: String
    }
    
    struct TranscodingConfig: Codable {
        let width: Int
        let height: Int
        let fps: Int
        let bitrate: Int
        let mixedVideoLayout: MixedVideoLayout
        let backgroundColor: String // #000000
        let defaultUserBackgroundImage: String  //https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/cloud-recording/default-avatar.jpg"
    }
    
    struct BackgroundConfig: Codable {
        let uid: String
        let image_url: String
    }
    
    struct ClientRequest: Codable {
        let mixedVideoLayout: MixedVideoLayout
        let backgroundColor: String // "#000000"
        let defaultUserBackgroundImage: String // https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/cloud-recording/default-avatar.jpg",
        let backgroundConfig: [BackgroundConfig]
        let layoutConfig: [LayoutConfig]
    }
    
    struct AgoraData: Codable {
        let clientRequest: ClientRequest
    }
    
    let roomUUID: String
    let agoraData: AgoraData
    let agoraParams: AgoraParams
    
    var task: Task { .requestJSONEncodable(encodable: self) }
    var method: HttpMethod { .post }
    var responseType: UpdateLayoutResponse.Type { UpdateLayoutResponse.self }
    var path: String { "/v1/room/record/agora/update-layout" }
}
