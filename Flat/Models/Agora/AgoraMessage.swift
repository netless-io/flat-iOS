//
//  AgoraMessage.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AgoraMessage: Decodable {
    let message: String
    let sourceUserId: String
    let date: Date

    enum CodingKeys: String, CodingKey {
        case message = "payload"
        case sourceUserId = "src"
        case date = "ms"
    }
}
