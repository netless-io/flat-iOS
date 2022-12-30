//
//  URLRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

extension URLRequest {
    mutating func encoded(encodable: Encodable, encoder: JSONEncoder) throws -> URLRequest {
        do {
            let encodable = AnyEncodable(encodable)
            httpBody = try encoder.encode(encodable)
            let contentTypeHeaderName = "Content-Type"
            if value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                setValue("application/json; charset=utf-8", forHTTPHeaderField: contentTypeHeaderName)
            }
            return self
        } catch {
            throw ApiError.encode(message: error.localizedDescription)
        }
    }
}
