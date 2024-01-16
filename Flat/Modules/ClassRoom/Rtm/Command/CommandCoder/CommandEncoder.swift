//
//  CommandEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct CommandEncoder {
    let encoder: JSONEncoder = {
        let d = JSONEncoder()
        d.dateEncodingStrategy = .millisecondsSince1970
        return d
    }()
    
    fileprivate func nsDictionary(_ input: Encodable) -> NSDictionary? {
        do {
            let data = try encoder.encode(input)
            let dict = try JSONSerialization.jsonObject(with: data) as? NSDictionary
            return dict
        }
        catch {
            logger.error("encode \(self) \(error)")
            return nil
        }
    }
    
    func encode(_ command: RtmCommand) throws -> Data {
        let t: RtmCommandType
        let v: NSDictionary
        switch command {
        case let .roomExpire(roomUUID: roomUUID, expireInfo: info):
            t = .roomExpire
            if let nsInfo = nsDictionary(info) {
                v = ["roomUUID": roomUUID, "expireInfo": nsInfo]
            } else {
                v = ["roomUUID": roomUUID]
            }
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
        case .reward(roomUUID: let roomUUID, userUUID: let userUUID):
            t = .reward
            v = ["roomUUID": roomUUID, "userUUID": userUUID]
        case .newUserEnter(roomUUID: let roomUUID, userUUID: let userUUID, userInfo: let userInfo):
            t = .newUserEnter
            if let dict = nsDictionary(userInfo) {
                v = ["roomUUID": roomUUID, "userUUID": userUUID, "userInfo": dict]
            } else {
                v = ["roomUUID": roomUUID, "userUUID": userUUID]
            }
            
        }
        let dic: NSDictionary = ["t": t.rawValue, "v": v]
        let data = try JSONSerialization.data(withJSONObject: dic)
        return data
    }
}
