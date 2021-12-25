//
//  HistoryMessageSourceRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

// https://docs.agora.io/cn/Real-time-Messaging/rtm_get_event?platform=restful#a-namecreate_history_resa%E5%88%9B%E5%BB%BA%E5%8E%86%E5%8F%B2%E6%B6%88%E6%81%AF%E6%9F%A5%E8%AF%A2%E8%B5%84%E6%BA%90-api%EF%BC%88post%EF%BC%89
struct HistoryMessageSourceRequest: AgoraRequest, Encodable {
    enum Order: String, Encodable {
        case desc
        case asc
    }
    
    struct Filter: Encodable {
        // channelId
        let destination: String
        let startTime: Date
        let endTime: Date
    }
    
    let filter: Filter
    let offSet: Int
    let limit: Int = 100
    var path: String { "/rtm/message/history/query" }
    let responseType = AnyKeyDecodable<String>.self
    let order: Order = .desc

    enum CodingKeys: String, CodingKey {
        case limit
        case offSet
        case filter
        case order
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.setAnyCodingKey("location")
        return decoder
    }
}
