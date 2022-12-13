//
//  ParameterEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

protocol ParameterEncoder {
    func encode(request: URLRequest, _ parameters: [String: Any]) throws -> URLRequest
}
