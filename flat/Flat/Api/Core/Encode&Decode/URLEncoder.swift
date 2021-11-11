//
//  URLEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

class URLEncoder: ParameterEncoder {
    static let `default` = URLEncoder()
    
    func encode(request: URLRequest, _ parameters: [String : Any]) throws -> URLRequest {
        var request = request
        guard let url = request.url else {
            throw ApiError.encode(message: "url encode without url")
        }
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            request.url = urlComponents.url
        }
        if request.allHTTPHeaderFields?["Content-Type"] == nil {
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
    
    func query(_ parameters: [String: Any]) -> String {
        parameters.map { queryComponents(fromKey: $0.key, value: $0.value) }.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
    }
    
    func queryComponents(fromKey key: String, value: Any) -> (String, String) {
        switch value {
        case let bool as Bool:
            return (key, bool ? "true" : "false")
        default:
            return (key, "\(value)")
        }
    }
}
