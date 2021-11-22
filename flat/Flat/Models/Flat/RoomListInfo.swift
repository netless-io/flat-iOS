//
//  RoomListInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RoomListInfo: Decodable {
    let roomUUID: String
    let periodicUUID: String?
    let ownerUUID: String
    let roomType: ClassRoomType
    let title: String
    let beginTime: Date
    let endTime: Date
    let roomStatus: RoomStartStatus
    let ownerName: String
    let region: String
    let hasRecord: Bool
    let inviteCode: String
    
    var formatterInviteCode: String {
        inviteCode.split(every: 3).joined(separator: " ")
    }
}
