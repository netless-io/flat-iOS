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

class ClassroomStateHandlerImp: ClassroomStateHandler {
    let maxOnstageUserCount: Int
    let roomUUID: String
    let ownerUUID: String
    let isOwner: Bool
    let syncedStore: ClassRoomSyncedStore
    let rtm: Rtm
    let commandChannelId: String
    var commandChannel: RtmChannel!
    
    let error: PublishRelay<ClassroomStateError> = .init()
    let roomStartStatus: BehaviorRelay<RoomStartStatus>
    let banState: BehaviorRelay<Bool> = .init(value: true)
    let onStageIds: BehaviorRelay<[String]> = .init(value: [])
    let raisingHandIds: BehaviorRelay<[String]> = .init(value: [])
    let deviceState: BehaviorRelay<[String: DeviceState]> = .init(value: [:])
    let noticePublisher: PublishRelay<String> = .init()
    let banMessagePublisher: PublishRelay<Bool> = .init()
    let classroomModeState: BehaviorRelay<ClassroomMode> = .init(value: .lecture)
    
    var bag = DisposeBag()
    let commandEncoder = CommandEncoder()
    let commandDecoder = CommandDecoder()
    
    init(syncedStore: ClassRoomSyncedStore,
         rtm: Rtm,
         commandChannelId: String,
         roomUUID: String,
         ownerUUID: String,
         isOwner: Bool,
         maxOnstageUserCount: Int,
         roomStartStatus: RoomStartStatus,
         whiteboardBannedAction: Observable<Void>,
         whiteboardRoomError: Observable<FastRoomError>) {
        self.syncedStore = syncedStore
        self.rtm = rtm
        self.commandChannelId = commandChannelId
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
        
        let r = rtm.error.map { _ ->  ClassroomStateError in .rtmRemoteLogin }
        let w = whiteboardRoomError.map { error -> ClassroomStateError in .whiteboardError(error) }
        Observable.merge(r, w)
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
                return self.rtm.joinChannelId(self.commandChannelId)
            }.do(onSuccess: { [weak self] channel in
                if let self = self {
                    self.commandChannel = channel
                    
                    PublishRelay.of(channel.newMessagePublish, self.rtm.p2pMessage)
                        .merge()
                        .flatMap { [weak self] value -> Observable<RtmCommand?> in
                            guard let self = self else { return .error("self not exist")}
                            return self.processCommandMessage(text: value.text, senderId: value.sender)
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
        classroomModeState.accept(result.roomState.classMode)
        raisingHandIds.accept(result.roomState.raiseHandUsers)
        onStageIds.accept(result.roomState.onStageUsers.filter { $0.value }.map { $0.key })
        log(log: "initialize state from synced store \(result)")
    }
    
    fileprivate func processCommandMessage(text: String, senderId: String) -> Observable<RtmCommand?> {
        do {
            let command = try commandDecoder.decode(text)
            switch command {
            case .updateRoomStatus(roomUUID: _, status: let status):
                roomStartStatus.accept(status)
            case .raiseHand(roomUUID: _, raiseHand: let raise):
                guard isOwner else { return .just(nil) }
                if banState.value { return .just(nil) }
                return syncedStore.getValues()
                    .flatMap { [weak self] result in
                        guard let self = self else { return .error("self not exist") }
                        let onStageUsersCount = result.roomState.onStageUsers.filter { $0.value }.count
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
            log(module: .rtm, level: .error, log: "process rtm command error \(error)")
            return .just(nil)
        }
    }
    
    func send(command: ClassroomCommand) -> Single<Void> {
        log(log: "try send command \(command)")
        do {
            switch command {
            case .updateRoomStartStatus(let status):
                let msg = try commandEncoder.encode(.updateRoomStatus(roomUUID: roomUUID, status: status))
                let serverRequest = RoomStatusUpdateRequest(newStatus: status, roomUUID: self.roomUUID)
                return ApiProvider.shared.request(fromApi: serverRequest).asSingle()
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self = self else { return .error("self not exist") }
                        return self.commandChannel.sendMessage(msg)
                    }.do(onSuccess: { [weak self] _ in
                        self?.roomStartStatus.accept(status)
                    })
            case .ban(let ban):
                let msg = try commandEncoder.encode(.ban(roomUUID: roomUUID, status: ban))
                try syncedStore.sendCommand(.banUpdate(ban))
                banMessagePublisher.accept(ban)
                return commandChannel.sendMessage(msg)
            case .disconnectUser(let uuid):
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<Void> in
                        guard let self = self else { return .error("self not exist ")}
                        try self.syncedStore.sendCommand(.deviceStateUpdate([uuid: .init(mic: false, camera: false)]))
                        try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: false]))
                        return .just(())
                    }
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
                let text = try commandEncoder.encode(.raiseHand(roomUUID: self.roomUUID, raiseHand: raiseHand))
                return rtm.sendP2PMessage(text: text, toUUID: ownerUUID)
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
                        
                        let newStageIds = result.roomState.onStageUsers.compactMapValues { _ in return false }
                        try self.syncedStore.sendCommand(.onStageUsersUpdate(newStageIds))
                        try self.syncedStore.sendCommand(.raiseHandUsersUpdate([]))
                        try self.syncedStore.sendCommand(.deviceStateUpdate(deviceState))
                        return .just(())
                    }
            }
        }
        catch {
            log(level: .error, log: "classroomStateImp send command \(command) error \(error)")
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
        
        let memberIds = Observable.combineLatest(
            initMembers,
            joinedMembers,
            removedMembers) { initValue, joinedValue, leftValue -> [String] in
            return initValue
                    .merging(joinedValue, uniquingKeysWith: +)
                    .merging(leftValue, uniquingKeysWith: +)
                    .filter { $0.value > 0 }
                    .map { $0.key }
        }
        
        let members = memberIds.flatMap { [weak self] ids -> Observable<[RoomUser]> in
            guard let self = self else { return .error("self not exist")}
            let noCacheIds = ids.filter { self.roomUserInfoCache[$0] == nil }
            let cachedUsers = ids.compactMap { self.roomUserInfoCache[$0]?.toRoomUser(uid:$0) }
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
                r.response.map { $0.value.toRoomUser(uid: $0.key)}
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
            onStageIds.asObservable()) { m, d, raiseHands, onStageIds -> [RoomUser] in
                let updatedUsers = m.map { user -> RoomUser in
                    var newUser = user
                    if let deviceState = d[newUser.rtmUUID] {
                        newUser.status.mic = deviceState.mic
                        newUser.status.camera = deviceState.camera
                    }
                    newUser.status.isSpeak = ownerUUID == newUser.rtmUUID || onStageIds.contains(newUser.rtmUUID)
                    newUser.status.isRaisingHand = raiseHands.contains(newUser.rtmUUID)
                    return newUser
                }
                return updatedUsers
        }.debug()
        observableMembers = result.share(replay: 1, scope: .forever)
        return observableMembers!
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
        case .classroomModeUpdate(let mode):
            classroomModeState.accept(mode)
        case .deviceStateUpdate(let state):
            deviceState.accept(state)
        case .raiseHandUsersUpdate(let users):
            raisingHandIds.accept(users)
        }
    }
}