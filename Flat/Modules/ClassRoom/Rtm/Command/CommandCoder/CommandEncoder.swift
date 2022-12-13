//
//  CommandEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct CommandEncoder {
    func encode(_ command: RtmCommand) throws -> Data {
        let t: RtmCommandType
        let v: NSDictionary
        switch command {
        case let .raiseHand(roomUUID: roomUUID, raiseHand: raiseHand):
            t = .raiseHand
            v = ["roomUUID": roomUUID, "raiseHand": raiseHand]
        case let .ban(roomUUID: roomUUID, status: status):
            t = .ban
            v = ["roomUUID": roomUUID, "status": status]
        case let .notice(roomUUID: roomUUID, text: text):
            t = .notice
            v = ["roomUUID": roomUUID, "text": text]
        case let .undefined(reason: reason):
            t = .undefine
            v = ["reason": reason]
        case let .updateRoomStatus(roomUUID: roomUUID, status: status):
            t = .updateRoomStatus
            v = ["roomUUID": roomUUID, "status": status.rawValue]
        }
        let dic: NSDictionary = ["t": t.rawValue, "v": v]
        let data = try JSONSerialization.data(withJSONObject: dic)
        return data
    }
}
