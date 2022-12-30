//
//  Message.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum Message {
    case user(UserMessage)
    case notice(String)

    var userId: String? {
        if case let .user(i) = self {
            return i.userId
        }
        return nil
    }
}

struct UserMessage: Codable {
    let userId: String
    let text: String
    let time: Date
}
