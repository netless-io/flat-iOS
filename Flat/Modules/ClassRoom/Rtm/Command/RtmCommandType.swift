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
}

struct RtmCommandType: RawRepresentable, Codable, Equatable {
    static let raiseHand = RtmCommandType(rawValue: "raise-hand")
    static let ban = RtmCommandType(rawValue: "ban")
    static let notice = RtmCommandType(rawValue: "notice")
    static let undefine = RtmCommandType(rawValue: "undefined")
    static let updateRoomStatus = RtmCommandType(rawValue: "update-room-status")

    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
