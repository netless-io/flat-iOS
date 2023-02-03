//
//  RoomUser.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct RoomUser: Hashable, CustomStringConvertible {
    var description: String {
        let maxLength = 8
        let truncateName = { name.count > maxLength ? String(name[name.startIndex ... name.index(name.startIndex, offsetBy: maxLength - 1)]) : name }
        let fixedName = { truncateName() + (0 ..< (maxLength - name.count)).map { _ in " " }.joined(separator: "") }
        let formattedName = name.count > maxLength ? truncateName() : fixedName()
        let onlineStr = isOnline ? "Online" : "Offline"
        return String(format: "\n  rtc: %d, rtm: %@, %@, %@, name: %@", rtcUID, rtmUUID, status.description, onlineStr, formattedName)
    }

    let rtmUUID: String
    let rtcUID: UInt
    let name: String
    let avatarURL: URL?
    var status: RoomUserStatus
    let isOnline: Bool
    
    static let empty: Self = .init(rtmUUID: "", rtcUID: 0, name: "", avatarURL: nil, isOnline: false)

    init(rtmUUID: String,
         rtcUID: UInt,
         name: String,
         avatarURL: URL?,
         status: RoomUserStatus = .default,
         isOnline: Bool = true)
    {
        self.rtmUUID = rtmUUID
        self.rtcUID = rtcUID
        self.name = name
        self.avatarURL = avatarURL
        self.status = status
        self.isOnline = isOnline
    }
}

struct RoomUserStatus: Hashable, CustomStringConvertible {
    var isSpeak: Bool
    var isRaisingHand: Bool
    var camera: Bool
    var mic: Bool
    var whiteboard: Bool

    var deviceState: DeviceState { .init(mic: mic, camera: camera) }

    static let `default` = RoomUserStatus(isSpeak: false, isRaisingHand: false, camera: false, mic: false, whiteboard: false)

    var description: String {
        let r = "✅"
        let f = "❌"
        return "⬆️: \(isSpeak ? r : f) 📝 : \(whiteboard ? r : f) 🙋‍♂️: \(isRaisingHand ? r : f) 📷: \(camera ? r : f) 🎤: \(mic ? r : f)"
    }

    init(isSpeak: Bool, isRaisingHand: Bool, camera: Bool, mic: Bool, whiteboard: Bool) {
        self.isSpeak = isSpeak
        self.isRaisingHand = isRaisingHand
        self.camera = camera
        self.mic = mic
        self.whiteboard = whiteboard
    }
}
