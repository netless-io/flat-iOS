//
//  ConversionTaskProgressRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct ConversionTaskProgressRequest: NetlessRequest {
    let uuid: String
    let type: ConversionTaskType
    let token: String
    
    var header: [String : String] { ["token": token] }
    var path: String { "/services/conversion/tasks/\(uuid)" }
    var task: Task { .requestURLEncodable(parameters: ["type": type.rawValue]) }
    let responseType = ConvertProgressDetail.self
}
