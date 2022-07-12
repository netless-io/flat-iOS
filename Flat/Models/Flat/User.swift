//
//  User.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct User: Codable {
    var name: String
    var avatar: URL
    let userUUID: String
    var token: String
    var hasPhone: Bool
}
