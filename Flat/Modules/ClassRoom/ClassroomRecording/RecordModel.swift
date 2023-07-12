//
//  RecordModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift

let singleRecordHeight: Int = 108
private let maxUserCount = 15
private let singleWidth = Int(CGFloat(singleRecordHeight) / ClassRoomLayoutRatioConfig.rtcItemRatio)
private let margin = Float(0)
private let videoWidth = singleWidth * maxUserCount + ((maxUserCount + 1) * Int(margin))
private let singleUserRatio: Float = .init(singleWidth) / Float(videoWidth)
private let marginRatioInRecord = margin / Float(videoWidth)
private let defaultAvatarUrl = "https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/cloud-recording/default-avatar.jpg"
private let defaultBackgroundColor = "#FFFFFF"

private let savedRecordModelKey = "RecordModelKey"
private let defaultRecordMode: AgoraRecordMode = .mix

// It start record when createModel function was called.
// The model will saved in userDefaults. (The model will be cleaned when stop function was called or the model was queried as a stoped record)
// Try query saved model, every time before create new record model.
class RecordModel: Codable {
    internal init(resourceId: String, sid: String, roomUUID: String, startDate: Date, currentLayout: MixLayout) {
        self.resourceId = resourceId
        self.sid = sid
        self.roomUUID = roomUUID
        self.startDate = startDate
        self.currentLayout = currentLayout
        loopToUpdateServerEndTime()
    }

    fileprivate static var savedRecord: RecordModel? {
        get {
            if let data = UserDefaults.standard.value(forKey: savedRecordModelKey) as? Data {
                do {
                    let item = try JSONDecoder().decode(Self.self, from: data)
                    logger.info("get savedRecord \(item)")
                    return item
                } catch {
                    logger.error("get savedRecord error, \(error)")
                    return nil
                }
            }
            return nil
        }
        set {
            do {
                if let newValue {
                    let data = try JSONEncoder().encode(newValue)
                    UserDefaults.standard.setValue(data, forKey: savedRecordModelKey)
                    logger.info("set savedRecord \(newValue)")
                } else {
                    UserDefaults.standard.setValue(nil, forKey: savedRecordModelKey)
                    logger.info("set savedRecord nil")
                }
            } catch {
                logger.error("set savedRecord error \(error)")
                return
            }
        }
    }

    let resourceId: String
    let sid: String
    let roomUUID: String
    let startDate: Date

    static func fetchSavedRecordModel() -> Single<RecordModel?> {
        guard let model = savedRecord else { return .just(nil) }
        return model
            .queryIfStop()
            .map { stop -> RecordModel? in stop ? nil : model }
            .asSingle()
    }

    static func create(fromRoomUUID uuid: String, users: [RoomUser]) -> Observable<RecordModel> {
        let maxRetryTime = 3
        let errorRetryTimeInterval = 3
        let clientRequest = RecordAcquireRequest.ClientRequest.default
        let acquireAgoraData = RecordAcquireRequest.AgoraData(clientRequest: clientRequest)
        return ApiProvider.shared
            .request(fromApi: RecordAcquireRequest(agoraData: acquireAgoraData, roomUUID: uuid))
            .flatMap { start(fromRoomUUID: uuid, resourceId: $0.resourceId, users: users) }
            .map { response, layout in
                RecordModel(resourceId: response.resourceId, sid: response.sid, roomUUID: uuid, startDate: Date(), currentLayout: layout)
            }
            .retry(when: { error in
                error.enumerated().flatMap { index, _ -> Observable<Int> in
                    let times = index + 1
                    if times >= maxRetryTime {
                        return .error("over max retry time")
                    } else {
                        logger.info("start retry create record, times \(times)")
                        return .timer(.seconds(errorRetryTimeInterval * times), scheduler: MainScheduler.instance)
                    }
                }
            })
            .do(onNext: { model in
                RecordModel.savedRecord = model
            })
    }

    func endRecord() -> Observable<Void> {
        RecordModel.savedRecord = nil
        let request = StopRecordRequest(roomUUID: roomUUID, agoraParams: .init(resourceid: resourceId, sid: sid, mode: defaultRecordMode))
        return ApiProvider.shared.request(fromApi: request)
            .mapToVoid()
            .asInfallible(onErrorJustReturn: ())
            .asObservable()
    }

    static func usersConfigs(from users: [RoomUser]) -> MixLayout {
        let joinedUsers = Array(users.prefix(maxUserCount))
        let sortedUsers = joinedUsers.sorted { u1, u2 in
            let isTeacher = u1.rtmUUID == AuthStore.shared.user?.userUUID
            if isTeacher {
                return true
            }
            return u1.rtcUID < u2.rtcUID
        }
        let backgroundConfig: [BackgroundConfig] = sortedUsers.map {
            .init(uid: $0.rtcUID.description, image_url: $0.avatarURL?.absoluteString ?? "")
        }
        let layoutConfig: [LayoutConfig] = sortedUsers.enumerated().map { index, _ in
            let x = (Float(index + 1) * marginRatioInRecord) + (Float(index) * singleUserRatio)
            return .init(x_axis: x, y_axis: 0, width: singleUserRatio, height: 1)
        }
        return .init(layouts: layoutConfig, backgrounds: backgroundConfig)
    }

    struct MixLayout: Codable, Equatable {
        let layouts: [LayoutConfig]
        let backgrounds: [BackgroundConfig]
    }

    var currentLayout: MixLayout
    func updateLayout(users: [RoomUser]) -> Observable<Void> {
        let newLayout = Self.usersConfigs(from: users)
        if currentLayout == newLayout {
            return .just(())
        }
        let clientRequest = UpdateLayoutRequest.ClientRequest(mixedVideoLayout: .custom,
                                                              backgroundColor: defaultBackgroundColor,
                                                              defaultUserBackgroundImage: defaultAvatarUrl,
                                                              backgroundConfig: newLayout.backgrounds,
                                                              layoutConfig: newLayout.layouts)
        let agoraData = UpdateLayoutRequest.AgoraData(clientRequest: clientRequest)
        let agoraParams = UpdateLayoutRequest.AgoraParams(resourceid: resourceId, mode: .mix, sid: sid)
        let request = UpdateLayoutRequest(roomUUID: roomUUID, agoraData: agoraData, agoraParams: agoraParams)
        return ApiProvider.shared
            .request(fromApi: request)
            .mapToVoid()
            .do(onCompleted: { [weak self] in
                self?.currentLayout = newLayout
            })
    }

    fileprivate func loopToUpdateServerEndTime() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self else { return }
            ApiProvider.shared.request(fromApi: UpdateRecordEndTimeRequest(roomUUID: self.roomUUID)) { _ in }
            self.loopToUpdateServerEndTime()
        }
    }

    fileprivate func queryIfStop() -> Observable<Bool> {
        let request = RecordQueryRequest(roomUUID: roomUUID, agoraParams: .init(resourceid: resourceId, sid: sid, mode: defaultRecordMode))
        return ApiProvider.shared.request(fromApi: request)
            .map(\.serverResponse.status.isStop)
            .asInfallible(onErrorJustReturn: true)
            .asObservable()
    }

    fileprivate static func start(
        fromRoomUUID uuid: String,
        resourceId: String,
        users: [RoomUser]
    )
        -> Observable<(StartRecordResponse, MixLayout)>
    {
        let layout = usersConfigs(from: users)
        let transCodingConfig = TranscodingConfig(width: videoWidth,
                                                  height: singleRecordHeight,
                                                  fps: 15,
                                                  bitrate: 500,
                                                  mixedVideoLayout: .custom,
                                                  backgroundColor: defaultBackgroundColor,
                                                  defaultUserBackgroundImage: defaultAvatarUrl,
                                                  backgroundConfig: layout.backgrounds,
                                                  layoutConfig: layout.layouts)
        let recordingConfig = StartRecordRequest.RecordingConfig(channelType: .communication,
                                                                 maxIdleTime: 5 * 60,
                                                                 subscribeUidGroup: 2,
                                                                 transcodingConfig: transCodingConfig)
        let clientRequest = StartRecordRequest.ClientRequest(recordingConfig: recordingConfig)
        let agoraData = StartRecordRequest.AgoraData(clientRequest: clientRequest)
        let agoraParams = StartRecordRequest.AgoraParams(resourceid: resourceId, mode: defaultRecordMode)
        let startRequest = StartRecordRequest(roomUUID: uuid, agoraData: agoraData, agoraParams: agoraParams)
        return ApiProvider.shared.request(fromApi: startRequest)
            .map { return ($0, layout) }
    }
}
