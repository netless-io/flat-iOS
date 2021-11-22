//
//  ClassRoomFactory.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/8.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard
import RxCocoa

struct ClassRoomFactory {
    struct DeviceStatus {
        let mic: Bool
        let camera: Bool
    }
    
    static func getClassRoomViewController(withPlayinfo playInfo: RoomPlayInfo,
                                            detailInfo: RoomInfo,
                                            deviceStatus: DeviceStatus = .init(mic: false, camera: false)) -> ClassRoomViewController {
        // Config Whiteboard
        let userName = AuthStore.shared.user?.name ?? ""
        let whiteSDkConig = WhiteSdkConfiguration.init(app: Env().netlessAppId)
        whiteSDkConig.renderEngine = .canvas
        whiteSDkConig.region = .CN
        whiteSDkConig.userCursor = true
        let payload: [String: String] = ["cursorName": userName]
        let roomConfig = WhiteRoomConfig(uuid: playInfo.whiteboardRoomUUID,
                        roomToken: playInfo.whiteboardRoomToken,
                        uid: AuthStore.shared.user?.userUUID ?? "",
                        userPayload: payload)
        let whiteboardViewController = WhiteboardViewController(sdkConfig: whiteSDkConig, roomConfig: roomConfig)
        
        // Config init state
        let initUser: RoomUser = .init(rtmUUID: playInfo.rtmUID,
                             rtcUID: playInfo.rtcUID,
                             name: AuthStore.shared.user?.name ?? "",
                             avatarURL: AuthStore.shared.user?.avatar,
                             status: .init(isSpeak: false,
                                           isRaisingHand: false,
                                           camera: deviceStatus.camera,
                                           mic: deviceStatus.mic))
        let state = ClassRoomState(roomType: detailInfo.roomType,
                                   roomOwnerRtmUUID: playInfo.ownerUUID,
                                   roomUUID: playInfo.roomUUID,
                                   messageBan: true,
                                   status: detailInfo.roomStatus,
                                   mode: .lecture,
                                   users: [initUser],
                                   userUUID: initUser.rtmUUID)
        
        // Config Rtm
        let rtm = ClassRoomRtm(rtmToken: playInfo.rtmToken,
                                rtmUserUUID: playInfo.rtmUID,
                                agoraAppId: Env().agoraAppId)
        
        // Config Rtc
        let rtcViewController = RtcViewController(token: playInfo.rtcToken,
                                                   channelId: playInfo.roomUUID,
                                                   rtcUid: playInfo.rtcUID)
        
        let controller = ClassRoomViewController(whiteboardViewController: whiteboardViewController,
                                                  rtcViewController: rtcViewController,
                                                  classRoomState: state,
                                                  rtm: rtm,
                                                  chatChannelId: playInfo.roomUUID,
                                                  commandChannelId: playInfo.roomUUID + "commands",
                                                  roomOwnerRtmUUID: playInfo.ownerUUID,
                                                  roomTitle: detailInfo.title,
                                                  beginTime: detailInfo.beginTime,
                                                  roomNumber: detailInfo.formatterInviteCode,
                                                  roomUUID: playInfo.roomUUID,
                                                  isTeacher: detailInfo.ownerUUID == playInfo.rtmUID,
                                                  userUUID: playInfo.rtmUID,
                                                  userName: initUser.name)
        return controller
    }
}
