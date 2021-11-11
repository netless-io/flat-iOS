//
//  ClassRoomFactory.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/8.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct ClassRoomFactory {
    struct DeviceStatus {
        let mic: Bool
        let camera: Bool
    }
    
    static func getClassRoomViewController(withPlayinfo playInfo: RoomPlayInfo,
                                           detailInfo: RoomInfo,
                                           deviceStatus: DeviceStatus) -> ClassRoomViewController1 {
        let vc = ClassRoomViewController1(rtmData: (playInfo.rtmToken, playInfo.roomUUID),
                                          whiteboardData: (playInfo.whiteboardRoomUUID, playInfo.whiteboardRoomToken),
                                          rtcData: (playInfo.roomUUID, playInfo.rtcToken, playInfo.rtcUID),
                                          roomUUID: playInfo.roomUUID,
                                          roomType: detailInfo.roomType,
                                          status: detailInfo.roomStatus,
                                          roomOwnerRtmUUID: detailInfo.ownerUUID,
                                          initUser: .init(rtmUUID: playInfo.rtmUID,
                                                          rtcUID: playInfo.rtcUID,
                                                          name: AuthStore.shared.user?.name ?? "",
                                                          avatarURL: AuthStore.shared.user?.avatar,
                                                          status: .init(isSpeak: false,
                                                                        isRaisingHand: false,
                                                                        camera: deviceStatus.camera,
                                                                        mic: deviceStatus.mic)),
                                          roomTitle: detailInfo.title,
                                          beginTime: detailInfo.beginTime,
                                          roomNumber: detailInfo.inviteCode)
        return vc
    }
}
