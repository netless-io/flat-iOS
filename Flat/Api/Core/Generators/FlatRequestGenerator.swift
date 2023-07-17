//
//  RequestGenerator.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class FlatRequestGenerator: Generator {
    var token: String?
    let host: String
    let timeoutInterval: TimeInterval
    let sessionId: String

    init(host: String, timeoutInterval: TimeInterval, sessionId: String) {
        self.host = host
        self.timeoutInterval = timeoutInterval
        self.sessionId = sessionId
    }

    func generateRequest(fromApi api: some Request) throws -> URLRequest {
        let fullPath = "\(host)\(api.path)"
        let url = URL(string: fullPath)!
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = api.method.rawValue
        if let token {
            request.addValue("Bearer " + token, forHTTPHeaderField: "authorization")
        }
        request.addValue(UUID().uuidString, forHTTPHeaderField: "x-request-id")
        request.addValue(sessionId, forHTTPHeaderField: "x-session-id")
        switch api.method {
        case .get:
            break
        case .post:
            let contentTypeHeaderName = "Content-Type"
            if request.value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: contentTypeHeaderName)
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: [String:String](), options: [])
        }
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
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: .flatEncoder)
        case let .requestCustomJSONEncodable(encodable: encodable, customEncoder: customEncoder):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: customEncoder)
        }
    }
}
