//
//  Api.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

protocol Request {
    associatedtype Response: Decodable

    var path: String { get }
    var method: HttpMethod { get }
    var responseType: Response.Type { get }
    var decoder: JSONDecoder { get }
    var task: Task { get }
    var header: [String: String] { get }
}

extension Request {
    var header: [String: String] { [:] }
}

extension Request where Self: Encodable {
    var task: Task { .requestJSONEncodable(encodable: self) }
}
