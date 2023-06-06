//
//  CommandType.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum RtmCommand {
    case raiseHand(roomUUID: String, raiseHand: Bool)
    case ban(roomUUID: String, status: Bool)
    case notice(roomUUID: String, text: String)
    case undefined(reason: String)
    case updateRoomStatus(roomUUID: String, status: RoomStartStatus)
    case requestDevice(roomUUID: String, deviceType: RequestDeviceType)
    case requestDeviceResponse(roomUUID: String, deviceType: RequestDeviceType, on: Bool)
    case notifyDeviceOff(roomUUID: String, deviceType: RequestDeviceType)
    case reward(roomUUID: String, userUUID: String)
    case newUserEnter(roomUUID: String, userUUID: String, userInfo: RoomUserInfo)
}

struct RtmCommandType: RawRepresentable, Codable, Equatable {
    static let raiseHand = RtmCommandType(rawValue: "raise-hand")
    static let ban = RtmCommandType(rawValue: "ban")
    static let notice = RtmCommandType(rawValue: "notice")
    static let undefine = RtmCommandType(rawValue: "undefined")
    static let updateRoomStatus = RtmCommandType(rawValue: "update-room-status")
    static let requestDevice = RtmCommandType(rawValue: "request-device")
    static let requestDeviceResponse = RtmCommandType(rawValue: "request-device-response")
    static let notifyDeviceOff = RtmCommandType(rawValue: "notify-device-off")
    static let reward = RtmCommandType(rawValue: "reward")
    static let newUserEnter = RtmCommandType(rawValue: "enter")

    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
