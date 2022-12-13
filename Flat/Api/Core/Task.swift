//
//  Task.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum Task {
    case requestPlain
    case requestJSONEncodable(encodable: Encodable)
    case requestURLEncodable(parameters: [String: Any])
    case requestCustomJSONEncodable(encodable: Encodable, customEncoder: JSONEncoder)
    case requestCustomURLEncodable(parameters: [String: Any], customEncoder: ParameterEncoder)
}
