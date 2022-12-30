//
//  ClassRoomStateHandler.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/4.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import RxRelay
import RxSwift
import Whiteboard

// The classroom state combined from syncedStore and rtm
// But rtc connection can also fire error
class ClassroomStateHandlerImp: ClassroomStateHandler {
    let maxWritableUsersCount: Int
    let roomUUID: String
    let ownerUUID: String
    let userUUID: String
    let isOwner: Bool
    let syncedStore: ClassRoomSyncedStore
    let rtm: Rtm
    var commandChannel: RtmChannel!
    let commandChannelRequest: Single<RtmChannel>

    let error: PublishRelay<ClassroomStateError> = .init()
    let roomStartStatus: BehaviorRelay<RoomStartStatus>
    let banState: BehaviorRelay<Bool> = .init(value: true)
    let onStageIds: BehaviorRelay<[String]> = .init(value: [])
    let whiteboardIds: BehaviorRelay<[String]> = .init(value: [])
    let raisingHandIds: BehaviorRelay<[String]> = .init(value: [])
    let deviceState: BehaviorRelay<[String: DeviceState]> = .init(value: [:])
    let noticePublisher: PublishRelay<String> = .init()
    let banMessagePublisher: PublishRelay<Bool> = .init()
    let requestDevicePublisher: PublishRelay<RequestDeviceType> = .init()
    let requestDeviceResponsePublisher: PublishRelay<DeviceRequestResponse> = .init()
    let notifyDeviceOffPublisher: PublishRelay<RequestDeviceType> = .init()

    var bag = DisposeBag()
    let commandEncoder = CommandEncoder()
    let commandDecoder = CommandDecoder()

    init(syncedStore: ClassRoomSyncedStore,
         rtm: Rtm,
         commandChannelRequest: Single<RtmChannel>,
         roomUUID: String,
         ownerUUID: String,
         userUUID: String,
         isOwner: Bool,
         maxWritableUsersCount: Int,
         roomStartStatus: RoomStartStatus,
         whiteboardBannedAction: Observable<Void>,
         whiteboardRoomError: Observable<FastRoomError>,
         rtcError: Observable<RtcError>)
    {
        self.syncedStore = syncedStore
        self.rtm = rtm
        self.commandChannelRequest = commandChannelRequest
        self.roomUUID = roomUUID
        self.ownerUUID = ownerUUID
        self.userUUID = userUUID
        self.isOwner = isOwner
        self.maxWritableUsersCount = maxWritableUsersCount
        self.roomStartStatus = .init(value: roomStartStatus)
        syncedStore.delegate = self

        whiteboardBannedAction
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.roomStartStatus.accept(.Stopped)
            })
            .disposed(by: bag)

        let r = rtm.error.map { error -> ClassroomStateError in
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
                guard let self else { return .error("self not exist") }
                return self.commandChannelRequest
            }.do(onSuccess: { [weak self] channel in
                if let self {
                    self.commandChannel = channel

                    PublishRelay.of(channel.rawDataPublish, self.rtm.p2pMessage)
                        .merge()
                        .flatMap { [weak self] value -> Observable<RtmCommand?> in
                            guard let self else { return .error("self not exist") }
                            return self.processCommandMessage(data: value.data, senderId: value.sender)
                        }
                        .subscribe()
                        .disposed(by: self.bag)
                }
            })
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self else { return .error("self not exist") }
                return .create { [weak self] ob in
                    guard let self else {
                        ob(.failure("self deinit"))
                        return Disposables.create()
                    }
                    self.syncedStore.getValues { r in
                        switch r {
                        case let .success(result):
                            self.initializeState(from: result)
                            ob(.success(()))
                        case let .failure(error):
                            ob(.failure(error))
                        }
                    }
                    return Disposables.create()
                }
            }
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self else { return .error("self not exist") }
                if !self.isOwner { return .just(()) }
                return self.send(command: .updateRoomStartStatus(.Started))
            }
    }

    fileprivate func initializeState(from result: ClassRoomSyncedStore.SyncedStoreSuccessValue) {
        deviceState.accept(result.deviceState)
        banState.accept(result.roomState.ban)
        raisingHandIds.accept(result.roomState.raiseHandUsers)
        onStageIds.accept(result.onStageUsers.filter(\.value).map(\.key))
        whiteboardIds.accept(result.whiteboardUsers.filter(\.value).map(\.key))
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
                        guard let self else { return .error("self not exist") }
                        let onStageUsersCount = result.onStageUsers.filter(\.value).count
                        if onStageUsersCount >= self.maxWritableUsersCount { return .error("can't accept more onstage users") }
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
            case .requestDevice(_, deviceType: let type):
                requestDevicePublisher.accept(type)
            case .requestDeviceResponse(_, deviceType: let deviceType, on: let on):
                return memberNameQueryProvider()([senderId])
                    .flatMap { [weak self] userDic -> Observable<Void> in
                        guard let self else { return .error("self not exist") }
                        guard let info = userDic[senderId] else { return .error("user not exist") }
                        self.requestDeviceResponsePublisher.accept(.init(type: deviceType, userUUID: senderId, userName: info.name, isOn: on))
                        return .just(())
                    }
                    .map { command }
            case .notifyDeviceOff(_, deviceType: let type):
                notifyDeviceOffPublisher.accept(type)
            }
            return .just(command)
        } catch {
            logger.error("process rtm command error \(error)")
            return .just(nil)
        }
    }

    func send(command: ClassroomCommand) -> Single<Void> {
        logger.info("try send command \(command)")
        do {
            switch command {
            case let .updateRoomStartStatus(status):
                let msgData = try commandEncoder.encode(.updateRoomStatus(roomUUID: roomUUID, status: status))
                let serverRequest = RoomStatusUpdateRequest(newStatus: status, roomUUID: roomUUID)
                return ApiProvider.shared.request(fromApi: serverRequest).asSingle()
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self else { return .error("self not exist") }
                        return self.commandChannel.sendRawData(msgData)
                    }.do(onSuccess: { [weak self] _ in
                        self?.roomStartStatus.accept(status)
                    })
            case let .ban(ban):
                let msgData = try commandEncoder.encode(.ban(roomUUID: roomUUID, status: ban))
                try syncedStore.sendCommand(.banUpdate(ban))
                banMessagePublisher.accept(ban)
                return commandChannel.sendRawData(msgData)
            case let .disconnectUser(uuid):
                return syncedStore.getValues()
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self else { return .error("self not exist ") }
                        try self.syncedStore.sendCommand(.deviceStateUpdate([uuid: .init(mic: false, camera: false)]))
                        try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: false]))
                        return .just(())
                    }
            case let .updateUserWhiteboardEnable(uuid: uuid, enable: enable):
                return syncedStore.getValues()
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self else { return .error("self not exist ") }
                        try self.syncedStore.sendCommand(.whiteboardUsersUpdate([uuid: enable]))
                        return .just(())
                    }
            case let .pickUserOnStage(uuid):
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<Void> in
                        guard let self else { return .error("self not exist ") }
                        if result.roomState.raiseHandUsers.contains(uuid) {
                            var raiseHandUsers = result.roomState.raiseHandUsers
                            raiseHandUsers.removeAll(where: { $0 == uuid })
                            try self.syncedStore.sendCommand(.raiseHandUsersUpdate(raiseHandUsers))
                        }
                        try self.syncedStore.sendCommand(.onStageUsersUpdate([uuid: true]))
                        return .just(())
                    }
            case let .updateRaiseHand(raiseHand):
                let msgData = try commandEncoder.encode(.raiseHand(roomUUID: roomUUID, raiseHand: raiseHand))
                return rtm.sendP2PMessage(data: msgData, toUUID: ownerUUID)
            case let .updateDeviceState(uuid: uuid, state: state):
                if userUUID == uuid { // Do anything to self is okay
                    try syncedStore.sendCommand(.deviceStateUpdate([uuid: state]))
                    return .just(())
                } else if isOwner {
                    return syncedStore.getValues()
                        .flatMap { [weak self] result -> Single<Void> in
                            guard let self else { return .just(()) }
                            let currentDeviceState = result.deviceState
                            guard let currentUserState = currentDeviceState[uuid] else { return .just(()) }
                            let turnOnMic = !currentUserState.mic && state.mic
                            let turnOnCamera = !currentUserState.camera && state.camera
                            let turnOffMic = currentUserState.mic && !state.mic
                            let turnOffCamera = currentUserState.camera && !state.camera
                            if turnOffMic || turnOffCamera { // Do when command contains turn off
                                try self.syncedStore.sendCommand(.deviceStateUpdate([uuid: state]))
                                // Notify the user who's device was turned off
                                if turnOffMic {
                                    let msgData = try self.commandEncoder.encode(.notifyDeviceOff(roomUUID: self.roomUUID, deviceType: .mic))
                                    return self.rtm.sendP2PMessage(data: msgData, toUUID: uuid)
                                }
                                if turnOffCamera {
                                    let msgData = try self.commandEncoder.encode(.notifyDeviceOff(roomUUID: self.roomUUID, deviceType: .camera))
                                    return self.rtm.sendP2PMessage(data: msgData, toUUID: uuid)
                                }
                                return .just(())
                            } else { // It only send the first command
                                if turnOnMic {
                                    let msgData = try self.commandEncoder.encode(.requestDevice(roomUUID: self.roomUUID, deviceType: .mic))
                                    return self.rtm.sendP2PMessage(data: msgData, toUUID: uuid)
                                }
                                if turnOnCamera {
                                    let msgData = try self.commandEncoder.encode(.requestDevice(roomUUID: self.roomUUID, deviceType: .camera))
                                    return self.rtm.sendP2PMessage(data: msgData, toUUID: uuid)
                                }
                                return .just(())
                            }
                        }
                }
                return .just(())
            case .allMute:
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<[String]> in
                        guard let self else { return .just([]) }
                        var deviceState = result.deviceState
                        var muteUsers: [String] = []
                        for key in deviceState.keys {
                            if key != self.ownerUUID {
                                let state = deviceState[key]!
                                if state.mic {
                                    muteUsers.append(key)
                                }
                                deviceState[key] = .init(mic: false, camera: state.camera)
                            }
                        }
                        try self.syncedStore.sendCommand(.deviceStateUpdate(deviceState))
                        return .just(muteUsers)
                    }
                    .flatMap { [weak self] users -> Single<Void> in
                        guard let self else { return .just(()) }
                        let msgs: [(data: Data, uuid: String)] = try users.map {
                            let data = try self.commandEncoder.encode(.notifyDeviceOff(roomUUID: self.roomUUID, deviceType: .mic))
                            return (data, $0)
                        }
                        return self.rtm.sendP2PMessageFromArray(msgs)
                    }
            case .stopInteraction:
                return syncedStore.getValues()
                    .flatMap { [weak self] result -> Single<Void> in
                        guard let self else { return .just(()) }
                        var deviceState = result.deviceState
                        for key in deviceState.keys {
                            if key != self.ownerUUID {
                                deviceState[key] = .init(mic: false, camera: false)
                            }
                        }

                        let newStageIds = result.onStageUsers.compactMapValues { _ in false }
                        try self.syncedStore.sendCommand(.onStageUsersUpdate(newStageIds))
                        try self.syncedStore.sendCommand(.raiseHandUsersUpdate([]))
                        try self.syncedStore.sendCommand(.deviceStateUpdate(deviceState))
                        return .just(())
                    }
            case .requestDeviceResponse(type: let type, on: let on):
                let msgData = try self.commandEncoder.encode(.requestDeviceResponse(roomUUID: self.roomUUID, deviceType: type, on: on))
                return self.rtm.sendP2PMessage(data: msgData, toUUID: ownerUUID)
            }
        } catch {
            logger.error("classroomStateImp send command \(command)")
            return .error(error)
        }
    }

    func memberNameQueryProvider() -> UserInfoQueryProvider {
        { [weak self] ids -> Observable<[String: UserBriefInfo]> in
            guard let self else {
                return .error("self not exist")
            }
            let noCacheIds = ids.filter { self.roomUserInfoCache[$0] == nil }
            let cachedUserPairs = ids.compactMap { id -> (String, UserBriefInfo)? in
                if let cache = self.roomUserInfoCache[id] {
                    return (id, .init(name: cache.name, avatar: URL(string: cache.avatarURL)))
                }
                return nil
            }
            let cachedResult: [String: UserBriefInfo] = .init(uniqueKeysWithValues: cachedUserPairs)
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
                .map { response -> [String: UserBriefInfo] in
                    let remoteValue = response.response.mapValues { UserBriefInfo(name: $0.name, avatar: URL(string: $0.avatarURL)) }
                    let mergedValue = remoteValue.merging(cachedResult, uniquingKeysWith: { $1 })
                    return mergedValue
                }
            return req
        }
    }

    var currentWhiteboardWritableUsers: [String] = []
    var currentOnStageUsers: [String: RoomUser] = [:]
    // Get members from initMembers / newMember / leftMember
    // Get member basic info (id, name, avatar)
    // Mix deviceState / raisingHand / onStage
    var roomUserInfoCache: [String: RoomUserInfo] = [:]
    var observableMembers: Observable<[RoomUser]>?
    func members() -> Observable<[RoomUser]> {
        if let observableMembers {
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
            removedMembers
        ) { initValue, joinedValue, leftValue -> [String] in
            initValue
                .merging(joinedValue, uniquingKeysWith: +)
                .merging(leftValue, uniquingKeysWith: +)
                .filter { $0.value > 0 }
                .map(\.key)
        }

        let sharedStageIds = onStageIds.share(replay: 1, scope: .forever)

        // Get member ids from stage ids and online member ids
        // For offline onstage users can display on the list
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
            guard let self else { return .error("self not exist") }
            let ids = idPairs.map(\.key)
            let noCacheIds = ids.filter { self.roomUserInfoCache[$0] == nil }
            let cachedUsers = ids.compactMap { self.roomUserInfoCache[$0]?.toRoomUser(uid: $0, isOnline: idPairs[$0] ?? false) }
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
                r.response.map { $0.value.toRoomUser(uid: $0.key, isOnline: idPairs[$0.key] ?? false) }
            }
            let totalUsers = reqUsers.map { users -> [RoomUser] in
                var r = cachedUsers
                r.append(contentsOf: users)
                return r
            }
            return totalUsers
        }

        let ownerUUID = ownerUUID
        let result = Observable.combineLatest(
            members,
            deviceState.asObservable(),
            raisingHandIds.asObservable(),
            sharedStageIds,
            whiteboardIds.asObservable()
        ) { onlineMembers, currentDeviceState, raiseHands, onStageIds, whiteboardIds -> [RoomUser] in
            let updatedUsers = onlineMembers.map { user -> RoomUser in
                var newUser = user
                if let deviceState = currentDeviceState[newUser.rtmUUID] {
                    newUser.status.mic = deviceState.mic
                    newUser.status.camera = deviceState.camera
                }
                newUser.status.isSpeak = ownerUUID == newUser.rtmUUID || onStageIds.contains(newUser.rtmUUID)
                newUser.status.isRaisingHand = raiseHands.contains(newUser.rtmUUID)
                newUser.status.whiteboard = ownerUUID == newUser.rtmUUID || whiteboardIds.contains(newUser.rtmUUID)
                return newUser
            }

            return updatedUsers
        }
        .map { unsortedUsers in
            unsortedUsers
                .sorted { a, b in
                    func sortNum(_ user: RoomUser) -> Int {
                        var r = 0
                        if user.rtmUUID == ownerUUID {
                            r += (1 << 4)
                        }
                        if user.status.isSpeak {
                            r += (1 << 3)
                        }
                        if user.status.whiteboard {
                            r += (1 << 2)
                        }
                        if user.status.isRaisingHand {
                            r += (1 << 1)
                        }
                        return r
                    }
                    let aNum = sortNum(a)
                    let bNum = sortNum(b)
                    if aNum == bNum {
                        return a.name.compare(b.name) == .orderedDescending
                    }
                    return aNum > bNum
                }
        }
        .debug()
        .do(onNext: { [weak self] users in
            let usersPair = users.filter(\.status.isSpeak).map { ($0.rtmUUID, $0) }
            self?.currentOnStageUsers = .init(uniqueKeysWithValues: usersPair)
            self?.currentWhiteboardWritableUsers = users
                .filter { $0.status.whiteboard || $0.status.isSpeak }
                .map(\.rtmUUID)
        })
        observableMembers = result.share(replay: 1, scope: .forever)
        return observableMembers!
    }

    func checkIfWritableUserOverMaxCount() -> Single<Bool> {
        if let observableMembers {
            return observableMembers
                .map { users in
                    users.filter(\.isUsingWhiteboardWritable).count
                }
                .map { [unowned self] in
                    $0 >= self.maxWritableUsersCount
                }
                .take(1)
                .asSingle()
        }
        return .just(true)
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
    func flatSyncedStoreDidReceiveCommand(_: ClassRoomSyncedStore, command: ClassRoomSyncedStore.Command) {
        switch command {
        case let .onStageUsersUpdate(idMap):
            onStageIds.accept(idMap.filter(\.value).map(\.key))
        case let .whiteboardUsersUpdate(idMap):
            whiteboardIds.accept(idMap.filter(\.value).map(\.key))
        case let .banUpdate(isBan):
            banState.accept(isBan)
        case let .deviceStateUpdate(state):
            deviceState.accept(state)
        case let .raiseHandUsersUpdate(users):
            raisingHandIds.accept(users)
        }
    }
}
