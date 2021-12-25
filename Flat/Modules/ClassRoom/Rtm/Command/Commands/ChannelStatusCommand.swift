//
//  ChannelStatusCommand.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

/// From p2p, use it to update classroom status
struct ChannelStatusCommand: Codable {
    let banMessage: Bool
    let roomStartStatus: RoomStartStatus
    let classRoomMode: ClassRoomMode
    let userStates: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case banMessage = "ban"
        case roomStartStatus = "rStatus"
        case classRoomMode = "rMode"
        case userStates = "uStates"
    }
}
