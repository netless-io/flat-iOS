//
//  RoomUser.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import DifferenceKit

struct RoomUser: Hashable, Differentiable {
    let rtmUUID: String
    let rtcUID: UInt
    let name: String
    let avatarURL: URL?
    var status: RoomUserStatus
    
    init(rtmUUID: String,
         rtcUID: UInt,
         name: String,
         avatarURL: URL?,
         status: RoomUserStatus = .default) {
        self.rtmUUID = rtmUUID
        self.rtcUID = rtcUID
        self.name = name
        self.avatarURL = avatarURL
        self.status = status
    }
}

struct RoomUserStatus: Hashable {
    var isSpeak: Bool
    var isRaisingHand: Bool
    var camera: Bool
    var mic: Bool
    
    static let `default` = RoomUserStatus(isSpeak: false, isRaisingHand: false, camera: false, mic: false)
    
    init(isSpeak: Bool, isRaisingHand: Bool, camera: Bool, mic: Bool) {
        self.isSpeak = isSpeak
        self.isRaisingHand = isRaisingHand
        self.camera = camera
        self.mic = mic
    }
    
    // Some string like 'SRCM'
    init(string: String) {
        isSpeak = string.contains("S")
        isRaisingHand = string.contains("R")
        camera = string.contains("C")
        mic = string.contains("M")
    }
    
    func toString() -> String {
        var r = ""
        if isSpeak {
            r.append("S")
        }
        if isRaisingHand {
            r.append("R")
        }
        if
            camera {
            r.append("C")
        }
        if mic {
            r.append("M")
        }
        return r
    }
}
