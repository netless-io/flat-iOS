//
//  SpeakCommand.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct SpeakCommand: Codable {
    let userUUID: String
    let speak: Bool
}
