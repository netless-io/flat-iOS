//
//  RequestGenerator.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class AgoraRequestGenerator: Generator {
    var agoraToken: String = ""
    var agoraUserId: String = ""
    let agoraAppId: String
    let timeoutInterval: TimeInterval
    let agoraApi: String = "https://api.agora.io"

    init(agoraAppId: String,
         timeoutInterval: TimeInterval)
    {
        self.agoraAppId = agoraAppId
        self.timeoutInterval = timeoutInterval
    }

    func generateRequest<T: Request>(fromApi api: T) throws -> URLRequest {
        let fullPath = "\(agoraApi)\(api.path)"
        let url = URL(string: fullPath)!
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = api.method.rawValue
        request.addValue(agoraToken, forHTTPHeaderField: "x-agora-token")
        request.addValue(agoraUserId, forHTTPHeaderField: "x-agora-uid")
        for (field, value) in api.header {
            request.addValue(value, forHTTPHeaderField: field)
        }
        switch api.task {
        case .requestPlain:
            return request
        case let .requestURLEncodable(parameters: parameters):
            return try URLEncoder.default.encode(request: request, parameters)
        case let .requestCustomURLEncodable(parameters: parameters, customEncoder: encoder):
            return try encoder.encode(request: request, parameters)
        case let .requestJSONEncodable(encodable: encodable):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: .agoraEncoder)
        case let .requestCustomJSONEncodable(encodable: encodable, customEncoder: customEncoder):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: customEncoder)
        }
    }
}
