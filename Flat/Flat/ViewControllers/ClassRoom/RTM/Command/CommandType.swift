//
//  CommandType.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

enum RtmCommand {
    case deviceState(DeviceStateCommand)
    case requestChannelStatus(RequestChannelStatusCommand)
    case roomStartStatus(RoomStartStatus)
    case channelStatus(ChannelStatusCommand)
    case banText(Bool)
    case speak([SpeakCommand])
    case classRoomMode(ClassRoomMode)
    case notice(String)
    case undefined(String)
    
    case raiseHand(Bool)
    case accpetRaiseHand(AccpetRaiseHandCommand)
    case cancelRaiseHand(Bool)
}

struct CommandType: RawRepresentable, Codable, Equatable {
    static let speak = CommandType(rawValue: "Speak")
    static let deviceState = CommandType(rawValue: "DeviceState")
    static let channelStatus =  CommandType(rawValue: "ChannelStatus")
    static let requestChannelStatus = CommandType(rawValue: "RequestChannelStatus")
    static let classRoomStartStatus = CommandType(rawValue: "RoomStatus")
    static let classRoomMode = CommandType(rawValue: "ClassMode")
    static let banText = CommandType(rawValue: "BanText")
    static let cancelHandRaising = CommandType(rawValue: "CancelHandRaising")
    static let acceptRaiseHand = CommandType(rawValue: "AcceptRaiseHand")
    static let raiseHand = CommandType(rawValue: "RaiseHand")
    static let notice = CommandType(rawValue: "Notice")
    
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
