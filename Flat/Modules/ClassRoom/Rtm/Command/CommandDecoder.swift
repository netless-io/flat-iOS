//
//  CommandDecoder.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct CommandDecoder {
    func decode(_ text: String) throws -> RtmCommand {
        guard let data = text.data(using: .utf8) else {
            throw "text2data error"
        }
        decode.setAnyCodingKey("t")
        let commandType = try decode.decode(AnyKeyDecodable<CommandType>.self, from: data).result
        decode.setAnyCodingKey("v")
        switch commandType {
        case .allOffStage:
            let value = try decode.decode(AnyKeyDecodable<Bool>.self, from: data).result
            return .allOffStage(value)
        case .deviceState:
            let value = try decode.decode(AnyKeyDecodable<DeviceStateCommand>.self, from: data).result
            return .deviceState(value)
        case .channelStatus:
            let value = try decode.decode(AnyKeyDecodable<ChannelStatusCommand>.self, from: data).result
            return .channelStatus(value)
        case .requestChannelStatus:
            let value = try decode.decode(AnyKeyDecodable<RequestChannelStatusCommand>.self, from: data).result
            return .requestChannelStatus(value)
        case .raiseHand:
            let value = try decode.decode(AnyKeyDecodable<Bool>.self, from: data).result
            return .raiseHand(value)
        case .acceptRaiseHand:
            let value = try decode.decode(AnyKeyDecodable<AcceptRaiseHandCommand>.self, from: data).result
            return .acceptRaiseHand(value)
        case .cancelHandRaising:
            let value = try decode.decode(AnyKeyDecodable<Bool>.self, from: data).result
            return .cancelRaiseHand(value)
        case .banText:
            let value = try decode.decode(AnyKeyDecodable<Bool>.self, from: data).result
            return .banText(value)
        case .speak:
            let items = try decode.decode(AnyKeyDecodable<[SpeakCommand]>.self, from: data).result
            return .speak(items)
        case .classRoomMode:
            let value = try decode.decode(AnyKeyDecodable<ClassRoomMode>.self, from: data).result
            return .classRoomMode(value)
        case .notice:
            let value = try decode.decode(AnyKeyDecodable<String>.self, from: data).result
            return .notice(value)
        case .classRoomStartStatus:
            let value = try decode.decode(AnyKeyDecodable<RoomStartStatus>.self, from: data).result
            return .roomStartStatus(value)
        default:
            return .undefined(text)
        }
    }
    
    let decode = JSONDecoder()
}
