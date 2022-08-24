//
//  ClassRoomStateHandler.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/4.
//  Copyright © 2022 agora.io. All rights reserved.
//

import RxSwift
import Whiteboard
import RxRelay
import Fastboard

// The classroom state combined from syncedStore and rtm
// But rtc connection can also fire error
class ClassroomStateHandlerImp: ClassroomStateHandler {
    let maxOnstageUserCount: Int
    let roomUUID: String
    let ownerUUID: String
    let isOwner: Bool
    let syncedStore: ClassRoomSyncedStore
    let rtm: Rtm
    var commandChannel: RtmChannel!
    let commandChannelRequest: Single<RtmChannel>
    
    let error: PublishRelay<ClassroomStateError> = .init()
    let roomStartStatus: BehaviorRelay<RoomStartStatus>
    let banState: BehaviorRelay<Bool> = .init(value: true)
    let onStageIds: BehaviorRelay<[String]> = .init(value: [])
    let raisingHandIds: BehaviorRelay<[String]> = .init(value: [])
    let deviceState: BehaviorRelay<[String: DeviceState]> = .init(value: [:])
    let noticePublisher: PublishRelay<String> = .init()
    let banMessagePublisher: PublishRelay<Bool> = .init()
    
    var bag = DisposeBag()
    let commandEncoder = CommandEncoder()
    let commandDecoder = CommandDecoder()
    
    init(syncedStore: ClassRoomSyncedStore,
         rtm: Rtm,
         commandChannelRequest: Single<RtmChannel>,
         roomUUID: String,
         ownerUUID: String,
         isOwner: Bool,
         maxOnstageUserCount: Int,
         roomStartStatus: RoomStartStatus,
         whiteboardBannedAction: Observable<Void>,
         whiteboardRoomError: Observable<FastRoomError>,
         rtcError: Observable<RtcError>) {
        self.syncedStore = syncedStore
        self.rtm = rtm
        self.commandChannelRequest = commandChannelRequest
        self.roomUUID = roomUUID
        self.ownerUUID = ownerUUID
        self.isOwner = isOwner
        self.maxOnstageUserCount = maxOnstageUserCount
        self.roomStartStatus = .init(value: roomStartStatus)
        syncedStore.delegate = self
        
        whiteboardBannedAction
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.roomStartStatus.accept(.Stopped)
            })
            .disposed(by: bag)
        
        let r = rtm.error.map { error ->  ClassroomStateError in
            switch error {
            case .reconnectingTimeout: return .rtmReconnectingTimeout
            case .remoteLogin: return .rtmRemoteLogin
            }
        }
        let wE = whiteboardRoomError.map { error -> ClassroomStateError in .whiteboardError(error) }
        let rE = rtcError.map { error -> ClassroomStateError in
            switch error {
            case .connectionLost:
                return .rtcConnectLost
            }
        }
        Observable.merge(r, wE, rE)
            .bind(to: error)
            .disposed(by: bag)
    }
    
    // 1. Rtm login
    // 2. Rtm channel join
    // 3. SyncedStore join
    func setup() -> Single<Void> {
        rtm.login()
            .flatMap { [weak self] _ -> Single<RtmChannel> in
                guard let self = self else { return .error("self not exist")}
                return self.commandChannelRequest
            }.do(onSuccess: { [weak self] channel in
                if let self = self {
                    self.commandChannel = channel
                    
                    PublishRelay.of(channel.rawDataPublish, self.rtm.p2pMessage)
                        .merge()
                        .flatMap { [weak self] value -> Observable<RtmCommand?> in
                            guard let self = self else { return .error("self not exist")}
                            return self.processCommandMessage(data: value.data, senderId: value.sender)
                        }
                        .subscribe()
                        .disposed(by: self.bag)
                }
            })
            .flatMap({ [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist")}
                return .create { [weak self] ob in
                    guard let self = self else {
                        ob(.failure("self deinit"))
                        return Disposables.create()
                    }
                    self.syncedStore.getValues { r in
                        switch r {
                        case .success(let result):
                            self.initializeState(from: result)
                            ob(.success(()))
                        case .failure(let error):
                            ob(.failure(error))
                        }
                    }
                    return Disposables.create()
                }
                
            })
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                if !self.isOwner { return .just(())}
                return self.send(command: .updateRoomStartStatus(.Started))
            }
    }
    
    fileprivate func initializeState(from result: ClassRoomSyncedStore.SyncedStoreSuccessValue) {
        deviceState.accept(result.deviceState)
        banState.accept(result.roomState.ban)
        raisingHandIds.accept(result.roomState.raiseHandUsers)
        onStageIds.accept(result.onStageUsers.filter { $0.value }.map { $0.key })
        logger.info("initialize state from synced store \(result)")
    }
    
    fileprivate func processCommandMessage(data: Data, senderId: String) -> Observable<RtmCommand?> {
        do {
            let command = try commandDecoder.decode(data)
            switch command {
            case .updateRoomStatus(roomUUID: _, status: let status):
                roomStartStatus.accept(status)
            case .raiseHand(roomUUID: _, raiseHand: let raise):
                guard isOwner else { return .just(nil) }
                if banState.value { return .just(nil) }
                return syncedStore.getValues()
                    .flatMap { [weak self] result in
                        guard let self = self else { return .error("self not exist") }
                        let onStageUsersCount = result.onStageUsers.filter { $0.value }.count
                        if onStageUsersCount >= self.maxOnstageUserCount { return .error("can't accept more onstage users") }
                        var users = result.roomState.raiseHandUsers
                        if raise, !users.contains(senderId) {
                            users.append(senderId)
                        } else if !raise, users.contains(senderId) {
                            users.removeAll(where: { $0 == senderId })
                        } else {
                            return .just(())
                        }
                        try self.syncedStore.sendCommand(.raiseHandUsersUpdate(users))
                        return .just(())
                    }
                    .map { command }
                    .asObservable()
            case .ban(roomUUID: _, status: let isBan):
                // This is just a message
                banMessagePublisher.accept(isBan)
            case .notice(roomUUID: _, text: let notice):
                noticePublisher.accept(notice)
            case .undefined: break
            }
            return .just(command)
        }
        catch {
            logger.error("process rtm command error \(error)")
            return .just(nil)
        }
    }
    
    func send(command: ClassroomCommand) -> Single<Void> {
        logger.info("try send command \(command)")
        do {
            switch command {
            case .updateRoomStartStatus(let status):
                let msgData = try commandEncoder.encode(.updateRoomStatus(roomUUID: roomUUID, status: status))
                let serverRequest = RoomStatusUpdateRequest(newStatus: status, roomUUID: self.roomUUID)
                return ApiProvider.shared.request(fromApi: serverRequest).asSingle()
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self = self else { return .error("self not exist") }
                        return self.commandChannel.sendRawData(msgData)
                    }.do(onSuccess: { [weak self] _ in
                        self?.roomStartStatus.accept(status)
                    })
            case .ban(let ban):
                let msgData = try commandEncoder.encode(.ban(roomUUID: roomUUID, status: ban))
                try syncedStore.sendCommand(.banUpdate(ban))
                banMessagePublisher.accept(ban)
                return commandChannel.sendRawData(msgData)
            case .disconnectUser(let uuid):
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<Void> in
                        guard let self = self else { return .error("self not exist ")}
                        try self.syncedStore.sendCommand(.deviceStateUpdate([uuid: .init(mic: false, camera: false)]))
                        try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: false]))
                        return .just(())
                    }
            case .pickUserOnStage(let uuid):
                try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: true]))
                return .just(())
            case .acceptRaiseHand(let uuid):
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<Void> in
                        guard let self = self else { return .error("self not exist") }
                        if result.roomState.raiseHandUsers.contains(uuid) {
                            var raiseHandUsers = result.roomState.raiseHandUsers
                            raiseHandUsers.removeAll(where: { $0 == uuid})
                            try self.syncedStore.sendCommand(.raiseHandUsersUpdate(raiseHandUsers))
                            try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: true]))
                        }
                        return .just(())
                    }
            case .updateRaiseHand(let raiseHand):
                let msgData = try commandEncoder.encode(.raiseHand(roomUUID: self.roomUUID, raiseHand: raiseHand))
                return rtm.sendP2PMessage(data: msgData, toUUID: ownerUUID)
            case .updateDeviceState(uuid: let uuid, state: let state):
                try syncedStore.sendCommand(.deviceStateUpdate([uuid: state]))
                return .just(())
            case .stopInteraction:
                return syncedStore.getValues()
                    .flatMap { [weak self] result  -> Single<Void> in
                        guard let self = self else { return .just(()) }
                        var deviceState = result.deviceState
                        for key in deviceState.keys {
                            if key != self.ownerUUID {
                                deviceState[key] = .init(mic: false, camera: false)
                            }
                        }
                        
                        let newStageIds = result.onStageUsers.compactMapValues { _ in return false }
                        try self.syncedStore.sendCommand(.onStageUsersUpdate(newStageIds))
                        try self.syncedStore.sendCommand(.raiseHandUsersUpdate([]))
                        try self.syncedStore.sendCommand(.deviceStateUpdate(deviceState))
                        return .just(())
                    }
            }
        }
        catch {
            logger.error("classroomStateImp send command \(command)")
            return .error(error)
        }
    }
    
    func memberNameQueryProvider() -> UsernameQueryProvider {
        return { [weak self] ids -> Observable<[String: String]> in
            guard let self = self else {
                return .error("self not exist")
            }
            let noCacheIds = ids.filter { self.roomUserInfoCache[$0] == nil }
            let cachedUserPairs = ids.compactMap { id -> (String, String)? in
                if let name = self.roomUserInfoCache[id]?.name {
                    return (id, name)
                }
                return nil
            }
            let cachedResult: [String: String] = .init(uniqueKeysWithValues: cachedUserPairs)
            if noCacheIds.isEmpty {
                return .just(cachedResult)
            }
            
            let memberRequest = MemberRequest(roomUUID: self.roomUUID, usersUUID: noCacheIds)
            
            let req = ApiProvider.shared
                .request(fromApi: memberRequest)
                .do(onNext: { [weak self] r in
                    for pair in r.response {
                        self?.roomUserInfoCache[pair.key] = pair.value
                    }
                })
                    .map { response -> [String: String] in
                        let remoteValue = response.response.mapValues { $0.name }
                        let mergedValue = remoteValue.merging(cachedResult, uniquingKeysWith: { return $1 })
                        return mergedValue
                    }
            return req
        }
    }
    
    var currentOnStageUsers: [String : RoomUser] = [:]
    // Get members from initMembers / newMember / leftMember
    // Get member basic info (id, name, avatar)
    // Mix deviceState / raisingHand / onStage
    var roomUserInfoCache: [String: RoomUserInfo] = [:]
    var observableMembers: Observable<[RoomUser]>?
    func members() -> Observable<[RoomUser]> {
        if let observableMembers = observableMembers {
            return observableMembers
        }
        let initMembers = commandChannel
            .getMembers()
            .map { members -> [String: Int] in
                let pair = members.map { ($0, 1) }
                return .init(uniqueKeysWithValues: pair)
            }
            .asObservable()
        
        let joinedMembers = commandChannel.newMemberPublisher
            .scan(into: [String: Int](), accumulator: { result, item in
                result[item] = result[item].map { $0 + 1 } ?? 1
            })
            .startWith([:])
        
        let removedMembers = commandChannel.memberLeftPublisher
            .scan(into: [String: Int](), accumulator: { result, item in
                result[item] = result[item].map { $0 - 1 } ?? -1
            })
            .startWith([:])
        
        let onlineMemberIds = Observable.combineLatest(
            initMembers,
            joinedMembers,
            removedMembers) { initValue, joinedValue, leftValue -> [String] in
            return initValue
                    .merging(joinedValue, uniquingKeysWith: +)
                    .merging(leftValue, uniquingKeysWith: +)
                    .filter { $0.value > 0 }
                    .map { $0.key }
        }
        
        let sharedStageIds = onStageIds.share(replay: 1, scope: .forever)
         
        let memberIds = Observable.combineLatest(sharedStageIds, onlineMemberIds) { onStage, online -> [String: Bool] in
            var result: [String: Bool] = [:]
            for id in online {
                result[id] = true
            }
            for id in onStage {
                if result[id] == nil {
                    result[id] = false
                }
            }
            return result
        }
        
        let members = memberIds.flatMap { [weak self] idPairs -> Observable<[RoomUser]> in
            guard let self = self else { return .error("self not exist")}
            let ids = idPairs.map { $0.key }
            let noCacheIds = ids.filter { self.roomUserInfoCache[$0] == nil }
            let cachedUsers = ids.compactMap { self.roomUserInfoCache[$0]?.toRoomUser(uid:$0, isOnline: idPairs[$0] ?? false) }
            if noCacheIds.isEmpty { return .just(cachedUsers) }
            let memberRequest = MemberRequest(roomUUID: self.roomUUID, usersUUID: noCacheIds)
            let req = ApiProvider.shared
                .request(fromApi: memberRequest)
                .do(onNext: { [weak self] r in
                    for pair in r.response {
                        self?.roomUserInfoCache[pair.key] = pair.value
                    }
                })
            let reqUsers = req.map { r -> [RoomUser] in
                r.response.map { $0.value.toRoomUser(uid: $0.key, isOnline: idPairs[$0.key] ?? false)}
            }
            let totalUsers = reqUsers.map { users -> [RoomUser] in
                var r = cachedUsers
                r.append(contentsOf: users)
                return r
            }
            return totalUsers
        }
        
        let ownerUUID = self.ownerUUID
        let result = Observable.combineLatest(
            members,
            deviceState.asObservable(),
            raisingHandIds.asObservable(),
            sharedStageIds) { onlineMembers, currentDeviceState, raiseHands, onStageIds -> [RoomUser] in
                let updatedUsers = onlineMembers.map { user -> RoomUser in
                    var newUser = user
                    if let deviceState = currentDeviceState[newUser.rtmUUID] {
                        newUser.status.mic = deviceState.mic
                        newUser.status.camera = deviceState.camera
                    }
                    newUser.status.isSpeak = ownerUUID == newUser.rtmUUID || onStageIds.contains(newUser.rtmUUID)
                    newUser.status.isRaisingHand = raiseHands.contains(newUser.rtmUUID)
                    return newUser
                }
                
                return updatedUsers
        }
        .debug()
        .do(onNext: { [weak self] users in
            let usersPair = users.filter({ $0.status.isSpeak }).map { ($0.rtmUUID, $0)}
            self?.currentOnStageUsers = .init(uniqueKeysWithValues: usersPair)
        })
        observableMembers = result.share(replay: 1, scope: .forever)
        return observableMembers!
    }
    
    func checkIfOnStageUserOverMaxCount() -> Single<Bool> {
        .just(currentOnStageUsers.count >= maxOnstageUserCount)
    }
    
    func destroy() {
        let bag = DisposeBag()
        syncedStore.destroy()
        rtm.leave().subscribe().disposed(by: bag)
        // lol! This function can be called even app is about to terminate
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            _ = bag
        }
    }
}

extension ClassroomStateHandlerImp: FlatSyncedStoreCommandDelegate {
    func flatSyncedStoreDidReceiveCommand(_ store: ClassRoomSyncedStore, command: ClassRoomSyncedStore.Command) {
        switch command {
        case .onStageUsersUpdate(let idMap):
            onStageIds.accept(idMap.filter { $0.value }.map { $0.key} )
        case .banUpdate(let isBan):
            banState.accept(isBan)
        case .deviceStateUpdate(let state):
            deviceState.accept(state)
        case .raiseHandUsersUpdate(let users):
            raisingHandIds.accept(users)
        }
    }
}
