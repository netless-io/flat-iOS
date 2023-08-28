//
//  StartConvertRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct StartConvertRequest: FlatRequest, Encodable {
    enum Result: Codable {
        struct TaskInfo: Codable {
            let taskToken: String
            let taskUUID: String
        }
        enum CodingKeys: String, CodingKey {
            case whiteboardConvert
            case whiteboardProjector
        }
        var taskToken: String {
            switch self {
            case .whiteboardConvert(let info): return info.taskToken
            case .whiteboardProjector(let info): return info.taskToken
            }
        }
        var taskUUID: String {
            switch self {
            case .whiteboardConvert(let info): return info.taskUUID
            case .whiteboardProjector(let info): return info.taskUUID
            }
        }
        
        case whiteboardProjector(TaskInfo)
        case whiteboardConvert(TaskInfo)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .whiteboardProjector(let a0):
                try container.encode(a0, forKey: .whiteboardProjector)
            case .whiteboardConvert(let a0):
                try container.encode(a0, forKey: .whiteboardConvert)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let value = try? container.decode(TaskInfo.self, forKey: .whiteboardProjector) {
                self = .whiteboardProjector(value)
                return
            }
            let info = try container.decode(TaskInfo.self, forKey: .whiteboardConvert)
            self = .whiteboardConvert(info)
        }
    }
    
    let fileUUID: String

    var path: String { "/v2/cloud-storage/convert/start" }
    var task: Task { .requestJSONEncodable(encodable: self) }
    var responseType: StartConvertRequest.Result.Type { StartConvertRequest.Result.self }
}
