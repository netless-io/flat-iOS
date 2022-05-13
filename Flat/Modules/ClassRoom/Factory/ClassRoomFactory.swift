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
import AgoraRtcKit
import Fastboard

struct ClassRoomFactory {
    struct DeviceStatus {
        let mic: Bool
        let camera: Bool
    }
    
    static func getClassRoomViewController(withPlayInfo playInfo: RoomPlayInfo,
                                            detailInfo: RoomInfo,
                                            deviceStatus: DeviceStatus) -> ClassRoomViewController {
        let fastRoomConfiguration: FastRoomConfiguration
        if #available(iOS 13.0, *) {
            fastRoomConfiguration = FastRoomConfiguration(appIdentifier: Env().netlessAppId,
                                                          roomUUID: playInfo.whiteboardRoomUUID,
                                                          roomToken: playInfo.whiteboardRoomToken,
                                                          region: .CN,
                                                          userUID: AuthStore.shared.user?.userUUID ?? "",
                                                          useFPA: userUseFPA)
        } else {
            fastRoomConfiguration = FastRoomConfiguration(appIdentifier: Env().netlessAppId,
                                                      roomUUID: playInfo.whiteboardRoomUUID,
                                                      roomToken: playInfo.whiteboardRoomToken,
                                                      region: .CN,
                                                      userUID: AuthStore.shared.user?.userUUID ?? "")
        }
        if var ua = fastRoomConfiguration.whiteSdkConfiguration.value(forKey: "netlessUA") as? [String] {
            let env = Env()
            let isFlat = Bundle.main.bundleIdentifier == "io.agora.flat"
            let productName = env.name.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: " ", with: "_")
            let str: String
            str = isFlat ? "FLAT/NETLESS_\(env.region)@\(env.version)" : "FLAT/\(productName)_\(env.region)@\(env.version)"
            ua.append(str)
            fastRoomConfiguration.whiteSdkConfiguration.setValue(ua, forKey: "netlessUA")
        }
        fastRoomConfiguration.whiteSdkConfiguration.userCursor = true
        let userName = AuthStore.shared.user?.name ?? ""
        let payload: [String: String] = ["cursorName": userName]
        fastRoomConfiguration.whiteRoomConfig.userPayload = payload
        fastRoomConfiguration.whiteRoomConfig.windowParams?.prefersColorScheme = .auto
        Fastboard.globalFastboardRatio = 1 / ClassRoomLayoutRatioConfig.whiteboardRatio
        let fastboardViewController = FastboardViewController(fastRoomConfiguration: fastRoomConfiguration)
        
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
        let rtc = Rtc(appId: Env().agoraAppId,
                      channelId: playInfo.roomUUID,
                      token: playInfo.rtcToken,
                      uid: playInfo.rtcUID,
                      screenShareInfo: playInfo.rtcShareScreen)
        let rtcViewController = RtcViewController(viewModel: .init(rtc: rtc,
                                                                   localUserRegular: { $0 == 0 || $0 == playInfo.rtcUID },
                                                                   userFetch: { rtcId -> RoomUser? in
            if rtcId == 0 { return state.users.value.first(where: { $0.rtcUID == playInfo.rtcUID })}
            return state.users.value.first(where: { $0.rtcUID == rtcId }) },
                                                                   userThumbnailStream: { uid -> AgoraVideoStreamType in
            guard let user = state.users.value.first(where: { $0.rtcUID == uid }) else { return .low }
            let isTeacher = user.rtmUUID == playInfo.ownerUUID
            return playInfo.roomType.thumbnailStreamType(isUserTeacher: isTeacher)
        }))
        
        let controller = ClassRoomViewController(fastboardViewController: fastboardViewController,
                                                 rtcViewController: rtcViewController,
                                                 classRoomState: state,
                                                 rtm: rtm,
                                                 chatChannelId: playInfo.roomUUID,
                                                 commandChannelId: playInfo.roomUUID + "commands",
                                                 roomOwnerRtmUUID: playInfo.ownerUUID,
                                                 roomTitle: detailInfo.title,
                                                 beginTime: detailInfo.beginTime,
                                                 endTime: detailInfo.endTime,
                                                 roomNumber: detailInfo.formatterInviteCode,
                                                 roomUUID: playInfo.roomUUID,
                                                 isTeacher: detailInfo.ownerUUID == playInfo.rtmUID,
                                                 userUUID: playInfo.rtmUID,
                                                 userName: initUser.name)
        return controller
    }
}
