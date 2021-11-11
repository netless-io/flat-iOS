//
//  RoomUser.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomUser {
    init(rtmUUID: String,
         rtcUID: UInt,
         name: String,
         avatarURL: URL?,
         status: RoomUserStatus?) {
        self.rtmUUID = rtmUUID
        self.rtcUID = rtcUID
        self.name = name
        self.avatarURL = avatarURL
        self.status = status
    }
    
    let rtmUUID: String
    let rtcUID: UInt
    let name: String
    let avatarURL: URL?
    
    var status: RoomUserStatus?
}
