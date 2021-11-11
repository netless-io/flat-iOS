//
//  RoomUserStatus.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomUserStatus: Hashable {
    var isSpeak: Bool
    var isRaisingHand: Bool
    var camera: Bool
    var mic: Bool
    
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
