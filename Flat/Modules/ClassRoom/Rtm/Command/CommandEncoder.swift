//
//  CommandEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct CommandEncoder {
    func encode(_ command: RtmCommand) throws -> String {
            let t: RtmCommandType
            let v: NSDictionary
            switch command {
            case .raiseHand(roomUUID: let roomUUID, raiseHand: let raiseHand):
                t = .raiseHand
                v = ["roomUUID": roomUUID, "raiseHand": raiseHand]
            case .ban(roomUUID: let roomUUID, status: let status):
                t = .ban
                v = ["roomUUID": roomUUID, "status": status]
            case .notice(roomUUID: let roomUUID, text: let text):
                t = .notice
                v = ["roomUUID": roomUUID, "text": text]
            case .undefined(reason: let reason):
                t = .undefine
                v = ["reason": reason]
            case .updateRoomStatus(roomUUID: let roomUUID, status: let status):
                t = .updateRoomStatus
                v = ["roomUUID": roomUUID, "status": status.rawValue]
            }
            let dic: NSDictionary = ["t": t.rawValue, "v": v]
            let data = try JSONSerialization.data(withJSONObject: dic)
            let str = String(data: data, encoding: .utf8)
            return str ?? ""
    }
}
