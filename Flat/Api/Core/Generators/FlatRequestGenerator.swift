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
    
    init(host: String,
        timeoutInterval: TimeInterval
    ) {
        self.host = host
        self.timeoutInterval = timeoutInterval
    }
    
    func generateRequest<T: Request>(fromApi api: T) throws -> URLRequest {
        let fullPath = "\(host)\(api.path)"
        let url = URL(string: fullPath)!
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = api.method.rawValue
        if let token = token {
            request.addValue("Bearer " + token, forHTTPHeaderField: "authorization")
        }
        switch api.method {
        case .get:
            break
        case .post:
            let contentTypeHeaderName = "Content-Type"
            if request.value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: contentTypeHeaderName)
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: [:], options: [])
        }
        for (field, value) in api.header {
            request.addValue(value, forHTTPHeaderField: field)
        }
        switch api.task {
        case .requestPlain:
            return request
        case .requestURLEncodable(parameters: let parameters):
            return try URLEncoder.default.encode(request: request, parameters)
        case .requestCustomURLEncodable(parameters: let parameters, customEncoder: let encoder):
            return try encoder.encode(request: request, parameters)
        case .requestJSONEncodable(encodable: let encodable):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: .flatEncoder)
        case .requestCustomJSONEncodable(encodable: let encodable, customEncoder: let customEncoder):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: customEncoder)
        }
    }
}

