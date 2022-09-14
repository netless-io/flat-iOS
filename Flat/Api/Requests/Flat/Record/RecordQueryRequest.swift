//
//  StopRecordRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct RecordQueryResponse: Codable {
    enum Status: Int, Codable {
        // : The cloud service has not started.
        case idle = 0
        // : The initialization is complete.
        case initComplete = 1
        // : The cloud service is starting.
        case starting = 2
        // : The cloud service is partially ready.
        case partialReady = 3
        // : The cloud service is ready.
        case ready = 4
        // : The cloud service is in progress.
        case inProgress = 5
        // : The cloud service receives the request to stop.
        case receiveToStop = 6
        // : The cloud service stops.
        case stop = 7
        // : The cloud service exits.
        case exit = 8
        // 0: The cloud service exits abnormally.
        case abnormallyExit = 20
        
        var isStop: Bool {
            switch self {
            case .receiveToStop, .stop, .exit, .abnormallyExit:
                return true
            default:
                return false
            }
        }
    }
    
    struct ServerResponse: Codable {
        let status: Status
    }
    let resourceId: String
    let sid: String
    let serverResponse: ServerResponse
}

struct RecordQueryRequest: FlatRequest, Encodable {
    struct AgoraParams: Codable {
        let resourceid: String
        let sid: String
        let mode: AgoraRecordMode
    }
    
    let roomUUID: String
    let agoraParams: AgoraParams
    var path: String { "/v1/room/record/agora/query" }
    
    var task: Task { .requestJSONEncodable(encodable: self) }
    var method: HttpMethod { .post }
    var responseType: RecordQueryResponse.Type { RecordQueryResponse.self }
}
