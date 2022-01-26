//
//  RecordModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift

fileprivate let maxUserCount = 17
fileprivate let singleHeight: Int = 84
fileprivate let singleWidth = Int(CGFloat(84) / ClassRoomLayoutRatioConfig.rtcItemRatio)
fileprivate let margin = Float(20)
fileprivate let videoWidth = singleWidth * maxUserCount + ((maxUserCount + 1) * Int(margin))
fileprivate let singleUserRatio: Float = Float(singleWidth) / Float(videoWidth)
fileprivate let marginRatio = margin / Float(videoWidth)
fileprivate let defaultAvatarUrl = "https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/cloud-recording/default-avatar.jpg"

struct RecordModel {
    let resourceId: String
    let sid: String
    let roomUUID: String
    let startDate: Date
    
    func updateLayout(roomState: ClassRoomState) -> Observable<Void> {
        let joinedUsers = Array(roomState.users.value.prefix(maxUserCount))
        let backgroundConfig: [UpdateLayoutRequest.BackgroundConfig] = joinedUsers.map {
            .init(uid: $0.rtcUID.description, image_url: $0.avatarURL?.absoluteString ?? "")
        }
        let layoutConfig: [UpdateLayoutRequest.LayoutConfig] = joinedUsers.enumerated().map { index, _ in
                .init(x_axis:  (Float(index + 1) * marginRatio) + (Float(index) * singleUserRatio), y_axis: 0, width: singleUserRatio, height: 1)
        }
        let clientRequest = UpdateLayoutRequest.ClientRequest(mixedVideoLayout: .custom,
                                                              backgroundColor: "#F3F6F9",
                                                              defaultUserBackgroundImage: defaultAvatarUrl,
                                                              backgroundConfig: backgroundConfig,
                                                              layoutConfig: layoutConfig)
        let agoraData = UpdateLayoutRequest.AgoraData(clientRequest: clientRequest)
        let agoraParams = UpdateLayoutRequest.AgoraParams(resourceid: resourceId, mode: .mix, sid: sid)
        let request = UpdateLayoutRequest(roomUUID: roomUUID, agoraData: agoraData, agoraParams: agoraParams)
        return ApiProvider.shared.request(fromApi: request).mapToVoid()
    }
    
    func endRecord() -> Observable<Void> {
        ApiProvider.shared.request(fromApi:
                                    StopRecordRequest(roomUUID: roomUUID, agoraParams: .init(resourceid: resourceId,
                                                                                             sid: sid,
                                                                                             mode: .mix)))
            .mapToVoid()
    }
    
    func updateServerEndTime() {
        ApiProvider.shared.request(fromApi: UpdateRecordEndTimeRequest(roomUUID: roomUUID)) { _ in
            return
        }
    }
    
    static func create(
        fromRoomUUID uuid: String,
        roomState: ClassRoomState
    ) -> Observable<RecordModel>
    {
        let clientRequest = RecordAcquireRequest.ClientRequest.default
        let acqurireAgoraData = RecordAcquireRequest.AgoraData(clientRequest: clientRequest)
        return ApiProvider.shared
            .request(fromApi: RecordAcquireRequest(agoraData: acqurireAgoraData, roomUUID: uuid))
            .flatMap {
                start(fromRoomUUID: uuid, roomState: roomState, resourceId: $0.resourceId)
            }
            .map {
                RecordModel(resourceId: $0.resourceId, sid: $0.sid, roomUUID: uuid, startDate: Date())
            }
    }
    
    fileprivate static func start(
        fromRoomUUID uuid: String,
        roomState: ClassRoomState,
        resourceId: String
    ) -> Observable<StartRecordResponse>
    {
        let joinedUsers = Array(roomState.users.value.prefix(maxUserCount))
        let backgroundConfig: [StartRecordRequest.BackgroundConfig] = joinedUsers.map {
            .init(uid: $0.rtcUID.description, image_url: $0.avatarURL?.absoluteString ?? "")
        }
        let layoutConfig: [StartRecordRequest.LayoutConfig] = joinedUsers.enumerated().map { index, _ in
                .init(x_axis:  (Float(index + 1) * marginRatio) + (Float(index) * singleUserRatio), y_axis: 0, width: singleUserRatio, height: 1)
        }
        let transcodeConfig = StartRecordRequest.TranscodingConfig(width: videoWidth,
                                                                   height: singleHeight,
                                                                   fps: 15,
                                                                   bitrate: 500,
                                                                   mixedVideoLayout: .custom,
                                                                   backgroundColor: "#F3F6F9",
                                                                   defaultUserBackgroundImage: defaultAvatarUrl,
                                                                   backgroundConfig: backgroundConfig,
                                                                   layoutConfig: layoutConfig)
        let recordingConfig = StartRecordRequest.RecordingConfig(channelType: 0,
                                                                 maxIdleTime: 60,
                                                                 subscribeUidGroup: maxUserCount,
                                                                 transcodingConfig: transcodeConfig)
        let clientRequest = StartRecordRequest.ClientRequest(recordingConfig: recordingConfig)
        let startAgoraData = StartRecordRequest.AgoraData(clientRequest: clientRequest)
        
        let agoraParams = StartRecordRequest.AgoraParams(resourceid: resourceId, mode: .mix)
        return ApiProvider.shared.request(fromApi: StartRecordRequest(roomUUID: uuid, agoraData: startAgoraData, agoraParams: agoraParams))
    }
}
