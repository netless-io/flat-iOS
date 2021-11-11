//
//  User.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct User: Codable {
    let name: String
    let avatar: URL
    let userUUID: String
    let token: String
}
