//
//  RecordAcquireRequest.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct RecordAcquireRequest: FlatRequest, Encodable {
    struct Response: Codable {
        let resourceId: String
    }

    struct ClientRequest: Codable {
//        let region: RecordAcquireRequest.Region
        let resourceExpiredHour: Int

        static let `default` = Self(resourceExpiredHour: 24)
    }

    struct AgoraData: Codable {
        let clientRequest: ClientRequest
    }

//    enum Region: String, Codable {
//        /// 中国区
//        case CN
//        /// 除中国大陆以外的亚洲区域
//        case AP
//        /// 欧洲
//        case EU
//        /// 北美
//        case NA
//    }

    let agoraData: AgoraData
    let roomUUID: String
    var task: Task { .requestJSONEncodable(encodable: self) }
    var path: String { "/v1/room/record/agora/acquire" }
    var method: HttpMethod { .post }
    var responseType: Response.Type { Response.self }
}
