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

struct ClassroomFactory {
    static func getClassRoomViewController(withPlayInfo playInfo: RoomPlayInfo,
                                            detailInfo: RoomBasicInfo,
                                            deviceStatus: DeviceState) -> ClassRoomViewController {
        let fastRoomConfiguration: FastRoomConfiguration
        let region: Region
        switch FlatRegion(rawValue: detailInfo.region) ?? .CN_HZ {
        case .CN_HZ:
            region = .CN
        case .US_SV:
            region = .US
        case .SG:
            region = .SG
        case .IN_MUM:
            region = .IN
        case .GB_LON:
            region = .GB
        case .none:
            region = .CN
        }
        
        if #available(iOS 13.0, *) {
            fastRoomConfiguration = FastRoomConfiguration(appIdentifier: Env().netlessAppId,
                                                          roomUUID: playInfo.whiteboardRoomUUID,
                                                          roomToken: playInfo.whiteboardRoomToken,
                                                          region: region,
                                                          userUID: AuthStore.shared.user?.userUUID ?? "",
                                                          useFPA: userUseFPA)
        } else {
            fastRoomConfiguration = FastRoomConfiguration(appIdentifier: Env().netlessAppId,
                                                      roomUUID: playInfo.whiteboardRoomUUID,
                                                      roomToken: playInfo.whiteboardRoomToken,
                                                      region: region,
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
        fastRoomConfiguration.whiteSdkConfiguration.enableSyncedStore = true
        let userName = AuthStore.shared.user?.name ?? ""
        let payload: [String: String] = ["cursorName": userName]
        fastRoomConfiguration.whiteRoomConfig.userPayload = payload
        fastRoomConfiguration.whiteRoomConfig.windowParams?.prefersColorScheme = .auto
        fastRoomConfiguration.whiteRoomConfig.disableEraseImage = true
        fastRoomConfiguration.whiteRoomConfig.isWritable = detailInfo.isOwner || detailInfo.roomType.interactionStrategy == .enable
        Fastboard.globalFastboardRatio = 1 / ClassRoomLayoutRatioConfig.whiteboardRatio
        let fastboardViewController = FastboardViewController(fastRoomConfiguration: fastRoomConfiguration)
        
        let camera = detailInfo.isOwner ? deviceStatus.camera : detailInfo.roomType != .bigClass
        let mic = detailInfo.isOwner ? deviceStatus.mic : detailInfo.roomType != .bigClass
        let initDeviceState = DeviceState(mic: mic, camera: camera)
        
        // Config Rtc
        let rtc = Rtc(appId: Env().agoraAppId,
                      channelId: playInfo.roomUUID,
                      token: playInfo.rtcToken,
                      uid: playInfo.rtcUID,
                      screenShareInfo: playInfo.rtcShareScreen)
        
        // Config Rtm
        let rtm = Rtm(rtmToken: playInfo.rtmToken,
                                rtmUserUUID: playInfo.rtmUID,
                                agoraAppId: Env().agoraAppId)
        
        // Config State imp
        let syncedStore = ClassRoomSyncedStore()
        fastboardViewController.bindStore = syncedStore
        
        let imp = ClassroomStateHandlerImp(syncedStore: syncedStore,
                                           rtm: rtm,
                                           commandChannelId: playInfo.commandChannelId,
                                           roomUUID: playInfo.roomUUID,
                                           ownerUUID: playInfo.ownerUUID,
                                           isOwner: playInfo.rtmUID == playInfo.ownerUUID,
                                           maxOnstageUserCount: detailInfo.roomType.maxOnstageUserCount,
                                           roomStartStatus: detailInfo.roomStatus,
                                           whiteboardBannedAction: fastboardViewController.isRoomBanned.filter { $0 }.asObservable().mapToVoid(),
                                           whiteboardRoomError: fastboardViewController.roomError.asObservable(),
                                           rtcError: rtc.errorPublisher.asObservable())
        
        let rtcViewController = RtcViewController(viewModel: .init(rtc: rtc,
                                                                   localUserRegular: { $0 == 0 || $0 == playInfo.rtcUID },
                                                                   userFetch: { rtcId -> RoomUser? in
            if rtcId == 0 { return imp.currentOnStageUsers[playInfo.rtmUID] }
            return imp.currentOnStageUsers.first(where: { $0.value.rtcUID == rtcId })?.value
        },
                                                                   userThumbnailStream: { rtcId -> AgoraVideoStreamType in
            guard let user = imp.currentOnStageUsers.first(where: { $0.value.rtcUID == rtcId })?.value else { return .low }
            let isTeacher = user.rtmUUID == playInfo.ownerUUID
            return playInfo.roomType.thumbnailStreamType(isUserTeacher: isTeacher)
        }))
        
        
        let alertProvider = DefaultAlertProvider()
        let vm = ClassRoomViewModel(stateHandler: imp,
                                     initDeviceState: initDeviceState,
                                     isOwner: detailInfo.isOwner,
                                     userUUID: playInfo.rtmUID,
                                     roomUUID: playInfo.roomUUID,
                                     roomType: detailInfo.roomType,
                                     chatChannelId: playInfo.chatChannelId,
                                     rtm: rtm,
                                     alertProvider: alertProvider)
        let controller = ClassRoomViewController(viewModel: vm,
                                                   fastboardViewController: fastboardViewController,
                                                   rtcListViewController: rtcViewController,
                                                   userListViewController: .init(userUUID: playInfo.rtmUID, roomOwnerRtmUUID: playInfo.ownerUUID),
                                                   inviteViewController: ShareManager.createShareActivityViewController(roomUUID: playInfo.roomUUID,
                                                                                                                        beginTime: detailInfo.beginTime,
                                                                                                                        title: detailInfo.title,
                                                                                                                        roomNumber: detailInfo.formatterInviteCode),
                                                   isOwner: detailInfo.isOwner,
                                                   ownerUUID: playInfo.ownerUUID)
        alertProvider.root = controller
        logger.info("joined classroom \(playInfo.roomUUID), \(String(describing: initDeviceState))")
        return controller
    }
}
