//
//  CommandEncoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct CommandEncoder {
    func encode(
        _ command: RtmCommand, withChannelId channelId: String? = nil) throws -> String {
            let t: CommandType
            let v: Encodable
            switch command {
            case .deviceState(let deviceStateCommand):
                t = .deviceState
                v = deviceStateCommand
            case .requestChannelStatus(let requestChannelStatusCommand):
                t = .requestChannelStatus
                v = requestChannelStatusCommand
            case .roomStartStatus(let roomStartStatus):
                t = .classRoomStartStatus
                v = roomStartStatus
            case .channelStatus(let channelStatusCommand):
                t = .channelStatus
                v = channelStatusCommand
            case .raiseHand(let bool):
                t = .raiseHand
                v = bool
            case .accpetRaiseHand(let accpetRaiseHandCommand):
                t = .acceptRaiseHand
                v = accpetRaiseHandCommand
            case .cancelRaiseHand(let bool):
                t = .cancelHandRaising
                v = bool
            case .banText(let bool):
                t = .banText
                v = bool
            case .speak(let array):
                t = .speak
                v = array
            case .classRoomMode(let classRoomMode):
                t = .classRoomMode
                v = classRoomMode
            case .notice(let string):
                t = .notice
                v = string
            case .undefined(let string):
                t = .init(rawValue: "undefined")
                v = string
            }
            var output: [String: AnyEncodable] = ["t": .init(t),
                                                  "v": .init(v)]
            if let channelId = channelId {
                output["r"] = AnyEncodable(channelId)
            }
            let data = try encoder.encode(output)
            let str = String(data: data, encoding: .utf8)
            return str ?? ""
    }
    
    let encoder = JSONEncoder()
}
