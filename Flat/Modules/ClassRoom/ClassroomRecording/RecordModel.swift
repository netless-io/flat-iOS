//
//  RecordModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift

fileprivate let savedRecordModelKey = "RecordModelKey"
fileprivate let defaultRecordMode: AgoraRecordMode = .individual

// It start record when createModel function was called.
// The model will saved in userDefaults. (The model will be cleaned when stop function was called or the model was queried as a stoped record)
// Try query saved model, every time before create new record model.
class RecordModel: Codable {
    internal init(resourceId: String, sid: String, roomUUID: String, startDate: Date) {
        self.resourceId = resourceId
        self.sid = sid
        self.roomUUID = roomUUID
        self.startDate = startDate
        loopToUpdateServerEndTime()
    }
    
    fileprivate static var savedRecord: RecordModel? {
        get {
            if let data = UserDefaults.standard.value(forKey: savedRecordModelKey) as? Data {
                do {
                    let item = try JSONDecoder().decode(Self.self, from: data)
                    logger.info("get savedRecord \(item)")
                    return item
                }
                catch {
                    logger.error("get savedRecord error, \(error)")
                    return nil
                }
            }
            return nil
        }
        set {
            do {
                if let newValue = newValue {
                    let data = try JSONEncoder().encode(newValue)
                    UserDefaults.standard.setValue(data, forKey: savedRecordModelKey)
                    logger.info("set savedRecord \(newValue)")
                } else {
                    UserDefaults.standard.setValue(nil, forKey: savedRecordModelKey)
                    logger.info("set savedRecord nil")
                }
            }
            catch {
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
            .map { stop -> RecordModel? in return stop ? nil : model }
            .asSingle()
    }
    
    static func create(fromRoomUUID uuid: String) -> Observable<RecordModel> {
        let maxRetryTime = 3
        let errorRetryTimeInterval = 3
        let clientRequest = RecordAcquireRequest.ClientRequest.default
        let acquireAgoraData = RecordAcquireRequest.AgoraData(clientRequest: clientRequest)
        return ApiProvider.shared
            .request(fromApi: RecordAcquireRequest(agoraData: acquireAgoraData, roomUUID: uuid))
            .flatMap { start(fromRoomUUID: uuid, resourceId: $0.resourceId) }
            .map { RecordModel(resourceId: $0.resourceId, sid: $0.sid, roomUUID: uuid, startDate: Date()) }
            .retry(when: { error in
                return error.enumerated().flatMap { index, _  -> Observable<Int> in
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
    
    fileprivate func loopToUpdateServerEndTime() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.updateServerEndTime()
            self.loopToUpdateServerEndTime()
        }
    }

    fileprivate func updateServerEndTime() {
        ApiProvider.shared.request(fromApi: UpdateRecordEndTimeRequest(roomUUID: roomUUID)) { _ in
            return
        }
    }
    
    fileprivate func queryIfStop() -> Observable<Bool> {
        let request = RecordQueryRequest(roomUUID: roomUUID, agoraParams: .init(resourceid: resourceId, sid: sid, mode: defaultRecordMode))
        return ApiProvider.shared.request(fromApi: request)
            .map { $0.serverResponse.status.isStop }
            .asInfallible(onErrorJustReturn: true)
            .asObservable()
    }
    
    fileprivate static func start(fromRoomUUID uuid: String, resourceId: String) -> Observable<StartRecordResponse> {
        let recordingConfig = StartRecordRequest.RecordingConfig(channelType: .communication,
                                                                 maxIdleTime: 5 * 60,
                                                                 subscribeUidGroup: 2,
                                                                 streamMode: .standard,
                                                                 videoStreamType: .small)
        let clientRequest = StartRecordRequest.ClientRequest(recordingConfig: recordingConfig)
        let startAgoraData = StartRecordRequest.AgoraData(clientRequest: clientRequest)
        let agoraParams = StartRecordRequest.AgoraParams(resourceid: resourceId, mode: defaultRecordMode)
        return ApiProvider.shared.request(fromApi: StartRecordRequest(roomUUID: uuid, agoraData: startAgoraData, agoraParams: agoraParams))
    }
}
