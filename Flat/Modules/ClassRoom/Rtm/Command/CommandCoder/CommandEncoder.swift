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
        case .requestDevice(roomUUID: let roomUUID, deviceType: let type):
            t = .requestDevice
            switch type {
            case .camera:
                v = ["roomUUID": roomUUID, "camera": true]
            case .mic:
                v = ["roomUUID": roomUUID, "mic": true]
            }
        case .requestDeviceResponse(roomUUID: let roomUUID, deviceType: let type, on: let on):
            t = .requestDeviceResponse
            switch type {
            case .camera:
                v = ["roomUUID": roomUUID, "camera": on]
            case .mic:
                v = ["roomUUID": roomUUID, "mic": on]
            }
        case .notifyDeviceOff(roomUUID: let roomUUID, deviceType: let type):
            t = .notifyDeviceOff
            switch type {
            case .camera:
                v = ["roomUUID": roomUUID, "camera": false]
            case .mic:
                v = ["roomUUID": roomUUID, "mic": false]
            }
        }
        let dic: NSDictionary = ["t": t.rawValue, "v": v]
        let data = try JSONSerialization.data(withJSONObject: dic)
        return data
    }
}
