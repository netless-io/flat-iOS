//
//  CommandDecoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct CommandDecoder {
    func decode(_ data: Data) throws -> RtmCommand {
        let dic = try JSONSerialization.jsonObject(with: data) as? NSDictionary
        guard let dic else { return .undefined(reason: "decode command error") }
        guard let title = dic["t"] as? String else { return .undefined(reason: "decode command title error") }
        let type = RtmCommandType(rawValue: title)
        guard let info = dic["v"] as? NSDictionary else { return .undefined(reason: "decode command info error") }
        guard let roomUUID = info["roomUUID"] as? String else { return .undefined(reason: "decode command roomUUID error") }
        switch type {
        case .raiseHand:
            guard let raiseHand = info["raiseHand"] as? Bool else { return .undefined(reason: "decode command raiseHand error") }
            return .raiseHand(roomUUID: roomUUID, raiseHand: raiseHand)
        case .ban:
            guard let isBan = info["status"] as? Bool else { return .undefined(reason: "decode command ban error") }
            return .ban(roomUUID: roomUUID, status: isBan)
        case .notice:
            guard let text = info["text"] as? String else { return .undefined(reason: "decode command notice error") }
            return .notice(roomUUID: roomUUID, text: text)
        case .updateRoomStatus:
            guard let statusStr = info["status"] as? String else { return .undefined(reason: "decode command update status error") }
            let status = RoomStartStatus(rawValue: statusStr)
            return .updateRoomStatus(roomUUID: roomUUID, status: status)
        case .requestDevice:
            if let camera = info["camera"] {
                return .requestDevice(roomUUID: roomUUID, deviceType: .camera)
            }
            if let mic = info["mic"] {
                return .requestDevice(roomUUID: roomUUID, deviceType: .mic)
            }
            fatalError("can't get this type")
        case .requestDeviceResponse:
            if let camera = info["camera"] as? Bool {
                return .requestDeviceResponse(roomUUID: roomUUID, deviceType: .camera, on: camera)
            }
            if let mic = info["mic"] as? Bool {
                return .requestDeviceResponse(roomUUID: roomUUID, deviceType: .mic, on: mic)
            }
            fatalError("can't get this type")
        case .notifyDeviceOff:
            if let _ = info["camera"] as? Bool {
                return .notifyDeviceOff(roomUUID: roomUUID, deviceType: .camera)
            }
            if let _ = info["mic"] as? Bool {
                return .notifyDeviceOff(roomUUID: roomUUID, deviceType: .mic)
            }
            fatalError("can't get this type")
        default:
            return .undefined(reason: "won't happen")
        }
    }

    let decode = JSONDecoder()
}
