//
//  AdvanceReplayViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/14.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import Whiteboard
import SyncPlayer
import RxRelay

class AdvanceReplayViewModel: NSObject {
    internal init(roomInfo: RoomBasicInfo, recordDetail: RecordDetailInfo) {
        self.roomInfo = roomInfo
        self.recordDetail = recordDetail
    }
    
    struct ReplayUserInfo {
        let userUUID: String
        let rtcUID: UInt
        let userName: String
        let avatar: URL?
        let videoURL: URL
        let onStage: Bool
    }
    
    struct ReplayUserPlayer {
        let user: ReplayUserInfo
        let player: AVPlayer
    }
    
    let roomInfo: RoomBasicInfo
    let recordDetail: RecordDetailInfo
    
    var currentIndex: Int? = nil
    
    lazy var syncedStore: ClassRoomSyncedStore = {
        let store = ClassRoomSyncedStore()
        store.delegate = self
        return store
    }()
    
    fileprivate let recordUserState: BehaviorRelay<[UInt: RoomUserStatus]> = .init(value: [:])
    var userUUIDToRtcUid: [String: UInt] = [:]
    
    struct PlayRecord {
        let player: SyncPlayer
        let users: [ReplayUserPlayer]
        let duration: TimeInterval
        let userState: Observable<[UInt: RoomUserStatus]>
    }
    
    func setupWhite(_ whiteboardView: WhiteBoardView, index: Int) -> Single<PlayRecord> {
        showLog = true
        
        currentIndex = index
        let config = WhiteSdkConfiguration(app: Env().netlessAppId)
        config.region = .CN
        config.userCursor = true
        config.enableSyncedStore = true
        config.useMultiViews = true
        config.enableSyncedStore = true
        
        whiteSDK = WhiteSDK(whiteBoardView: whiteboardView,
                            config: config,
                            commonCallbackDelegate: nil)
        
        let whitePlayerConfig = WhitePlayerConfig(room: recordDetail.whiteboardRoomUUID,
                                                  roomToken: recordDetail.whiteboardRoomToken)
        let windowParams = WhiteWindowParams()
        whitePlayerConfig.windowParams = windowParams
        
        let record = recordDetail.recordInfo[index]
        let beginTimeStamp = record.beginTime.timeIntervalSince1970
        let duration = record.endTime.timeIntervalSince(record.beginTime)
        whitePlayerConfig.beginTimestamp = NSNumber(value: beginTimeStamp)
        whitePlayerConfig.duration = NSNumber(value: duration)
        let whitePlayer = Observable<WhitePlayer>.create { [weak self] observer in
            guard let self = self else {
                observer.onError("self not exist")
                return Disposables.create()
            }
            self.whiteSDK.createReplayer(with: whitePlayerConfig, callbacks: nil) { [weak self] success, player, error in
                if let error = error {
                    observer.onError(error)
                } else if let player = player {
                    self?.syncedStore.destroy()
                    self?.syncedStore.setup(with: player)
                    observer.onNext(player)
                } else {
                    observer.onError("unknown player create error")
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
        
        return Observable
            .combineLatest(whitePlayer, getInvolvedUsersInfo()) { [weak self] wp, users -> PlayRecord in
                guard let self = self else { throw "self not exist" }

                self.userUUIDToRtcUid = .init(uniqueKeysWithValues: users.map({ user ->(String, UInt) in
                    return (user.userUUID, user.rtcUID)
                }))
                // Init room userStatus
                let initRoomUserStatus = users.map { user -> (UInt, RoomUserStatus) in
                    if user.userUUID == self.recordDetail.ownerUUID {
                        return (user.rtcUID, RoomUserStatus(isSpeak: true, isRaisingHand: false, camera: false, mic: false))
                    }
                    return (user.rtcUID, RoomUserStatus(isSpeak: false, isRaisingHand: false, camera: false, mic: false))
                }
                self.recordUserState.accept(.init(uniqueKeysWithValues: initRoomUserStatus))
                
                let videoPlayers = users.map {
                    ReplayUserPlayer(user: $0, player: AVPlayer(url: $0.videoURL))
                }
                var players: [AtomPlayer] = videoPlayers.map { $0.player }
                players.append(wp)
                let syncPlayer = SyncPlayer(players: players)
                syncPlayer.tolerance = 1
                return .init(player: syncPlayer, users: videoPlayers, duration: duration, userState: self.recordUserState.asObservable())
            }
            .asSingle()
    }
    
    func getInvolvedUsersInfo() -> Observable<[ReplayUserInfo]> {
        guard let baseURL = recordDetail.recordInfo.first?.videoURL else { return .error("no records") }
        let memberRequest = MemberRequest(roomUUID: roomInfo.roomUUID, usersUUID: nil)
        return ApiProvider.shared.request(fromApi: memberRequest)
            .compactMap { result -> [ReplayUserInfo] in
                let dic = result.response
                let values = dic.compactMap { key, value -> ReplayUserInfo? in
                    let replacedStr = "__uid_s_\(value.rtcUID)__uid_e_av.m3u8"
                    let replacedLink = baseURL.absoluteString.replacingOccurrences(of: ".m3u8", with: replacedStr)
                    if let targetLink = URL(string: replacedLink) {
                        return ReplayUserInfo(userUUID: key,
                                              rtcUID: value.rtcUID,
                                              userName: value.name,
                                              avatar: URL(string: value.avatarURL),
                                              videoURL: targetLink,
                                              onStage: true)
                    } else {
                        return nil
                    }
                }
                return values
            }
            .flatMap { unfilterUsers -> Observable<[ReplayUserInfo]> in
                let rs = unfilterUsers.map { user in
                    return URLSession.shared.rx
                        .response(request: URLRequest(url: user.videoURL))
                        .map { response, data in
                            return (user, response.statusCode == 200)
                        }
                }
                var queryResult: Observable<(ReplayUserInfo, Bool)>?
                rs.forEach { observable in
                    if let existResult = queryResult {
                        queryResult = existResult.concat(observable)
                    } else {
                        queryResult = observable
                    }
                }
                
                if let queryResult = queryResult {
                    let result = queryResult
                        .filter { $0.1 }
                        .reduce([ReplayUserInfo]()) { result, item in
                            var new = result
                            new.append(item.0)
                            return new
                        }
                    return result
                }
                
                return .just([])
            }
    }
    
    // MARK: - Lazy
    var whiteSDK: WhiteSDK!
}

extension AdvanceReplayViewModel: FlatSyncedStoreCommandDelegate {
    func flatSyncedStoreDidReceiveCommand(_ store: ClassRoomSyncedStore, command: ClassRoomSyncedStore.Command) {
        switch command {
        case .raiseHandUsersUpdate:
            return
        case .onStageUsersUpdate(let dictionary):
            var new = recordUserState.value
            for pair in dictionary {
                if let rtcUid = userUUIDToRtcUid[pair.key] {
                    new[rtcUid]?.isSpeak = pair.value
                }
            }
            recordUserState.accept(new)
        case .banUpdate:
            return
        case .deviceStateUpdate(let dictionary):
            var new = recordUserState.value
            for pair in dictionary {
                if let rtcUid = userUUIDToRtcUid[pair.key] {
                    new[rtcUid]?.camera = pair.value.camera
                    new[rtcUid]?.mic = pair.value.mic
                }
            }
            recordUserState.accept(new)
        }
    }
}
