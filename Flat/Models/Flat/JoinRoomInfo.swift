//
//  RoomJoinInfo.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct JoinRoomInfo: Decodable {
    let roomUUID: String
    let periodicUUID: String?
    let inviteCode: String
}
