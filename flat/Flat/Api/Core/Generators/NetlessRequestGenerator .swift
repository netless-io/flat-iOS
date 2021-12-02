//
//  NetlessRequestGenerator .swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

class NetlessRequestGenerator : Generator {
    let timeoutInterval: TimeInterval
    let netlessApi: String = "https://api.netless.link/v5"
    
    init(timeoutInterval: TimeInterval) {
        self.timeoutInterval = timeoutInterval
    }
    
    func generateRequest<T: Request>(fromApi api: T) throws -> URLRequest {
        let fullPath = "\(netlessApi)\(api.path)"
        let url = URL(string: fullPath)!
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = api.method.rawValue
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
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: .netlessEncoder)
        case .requestCustomJSONEncodable(encodable: let encodable, customEncoder: let customEncoder):
            return try request.encoded(encodable: AnyEncodable(encodable), encoder: customEncoder)
        }
    }
}

