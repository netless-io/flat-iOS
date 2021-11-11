//
//  RequestChannelStatusCommand.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RequestChannelStatusCommand: Codable {
    // only use when send rtm message to others
    struct RtmUserState: Codable {
        let name: String
        let camera: Bool
        let mic: Bool
        /** this field is only accepted from room creator */
        let isSpeak: Bool
    }
    
    let roomUUID: String
    // These users should response
    let userUUIDs: [String]
    // Inform others about current user states
    let user: RtmUserState
}
