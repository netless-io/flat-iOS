//
//  SetAuthUuidRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

extension LoginType {
    fileprivate var removeBindingKey: String {
        switch self {
        case .wechat: return "WeChat"
        default:
            let raw = self.rawValue
            return raw.first!.uppercased() + raw.dropFirst()
        }
    }
}

struct RemoveBindingRequest: FlatRequest {
    struct Response: Decodable {
        let token: String
    }

    let type: LoginType

    var task: Task { .requestJSONEncodable(encodable: ["target": type.removeBindingKey]) }
    var path: String { "/v1/user/binding/remove" }
    let responseType = Response.self
}
