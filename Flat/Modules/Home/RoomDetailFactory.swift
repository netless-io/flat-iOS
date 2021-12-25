//
//  RoomDetailFactory.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct RoomDetailViewControllerFactory {
    static func getRoomDetail(withListinfo info: RoomListInfo) -> RoomDetailViewController {
        RoomDetailViewController(info: .init(beginTime: info.beginTime,
                                             endTime: info.endTime,
                                             roomStatus: info.roomStatus,
                                             roomType: info.roomType,
                                             roomUUID: info.roomUUID,
                                             isOwner: info.ownerUUID == AuthStore.shared.user?.userUUID ?? "",
                                             formatterInviteCode: info.formatterInviteCode))
    }
    
    static func getRoomDetail(withInfo info: RoomInfo, roomUUID: String) -> RoomDetailViewController {
        RoomDetailViewController(info: .init(beginTime: info.beginTime,
                                             endTime: info.endTime,
                                             roomStatus: info.roomStatus,
                                             roomType: info.roomType,
                                             roomUUID: roomUUID,
                                             isOwner: info.ownerUUID == AuthStore.shared.user?.userUUID ?? "",
                                             formatterInviteCode: info.formatterInviteCode))
    }
}
