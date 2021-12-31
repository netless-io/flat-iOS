//
//  ClassRoomViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/10.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import RxCocoa
import RxSwift

let classStatusUpdateNotification = Notification.Name("classStatusUpdateNotification")

class ClassRoomViewModel {
    struct Input {
        let trigger: Driver<Void>
        let enterBackground: Driver<Void>
        let enterForeground: Driver<Void>
    }
    
    struct Output {
        let initRoom: Observable<Void>
        let leaveRoomTemporary: Observable<Void>
        let newCommand: Observable<RtmCommand>
        let memberLeft: Observable<String>
        let roomStopped: Driver<Void>
        let roomError: Observable<String>
    }
    
    struct SettingInput {
        let leaveTap: Driver<TapSource>
        let cameraTap: Driver<Void>
        let micTap: Driver<Void>
    }
    
    struct SettingOutput {
        let deviceTask: Driver<Void>
        let dismiss: Driver<Bool>
    }
    
    struct UserListInput {
        let stopInteractingTap: Driver<Void>
        let disconnectTap: Driver<RoomUser>
        let tapSomeUserRaiseHand: Driver<RoomUser>
        let tapSomeUserCamera: Driver<RoomUser>
        let tapSomeUserMic: Driver<RoomUser>
    }
    
    deinit {
        print(self, "deinit")
    }
    
    internal init(isTeacher: Bool,
                  chatChannelId: String,
                  commandChannelId: String,
                  userUUID: String,
                  state: ClassRoomState,
                  rtm: ClassRoomRtm,
                  alertProvider: AlertProvider) {
        self.isTeacher = isTeacher
        self.chatChannelId = chatChannelId
        self.commandChannelId = commandChannelId
        self.state = state
        self.rtm = rtm
        self.userUUID = userUUID
        self.alertProvider = alertProvider
    }
    
    var commandHandler: AnyChannelHandler!
    
    let userUUID: String
    let isTeacher: Bool
    let chatChannelId: String
    let commandChannelId: String
    let state: ClassRoomState
    let rtm: ClassRoomRtm
    let alertProvider: AlertProvider
    
    lazy var isWhiteboardEnable: Driver<Bool> = {
        if self.isTeacher { return .just(true) }
        if state.roomType.interactionStrategy == .enable { return .just(true) }
        return Driver.combineLatest(state.mode.asDriver(),
                             userSelf) { mode, user -> Bool in
            if user.status.isSpeak { return true }
            return mode.interactionEnable
        }
    }()
    
    lazy var raiseHandHide: Driver<Bool> = {
        Driver.combineLatest(state.mode.asDriver(),
                             userSelf) { [weak self] mode, user -> Bool in
            guard let self = self else {
                return true
            }
            if self.isTeacher { return true }
            let canSpeak: Bool
            if self.state.roomType.interactionStrategy == .enable {
                canSpeak = true
            } else if mode.interactionEnable {
                canSpeak = true
            } else {
                canSpeak = user.status.isSpeak
            }
            return canSpeak
        }
    }()
    
    lazy var raiseHandSelected: Driver<Bool> = userSelf.map { $0.status.isRaisingHand }
    
    lazy var userSelf: Driver<RoomUser> = {
        let userId = userUUID
        let userSelf =  state.users.asDriver()
            .map { $0.first(where: { $0.rtmUUID == userId })! }
        return userSelf
    }()
    
    lazy var rtcUsers: Driver<[RoomUser]> = {
        let type = state.roomType
        let ownerRtmUUID = state.roomOwnerRtmUUID
        return state.users
            .map { type.rtcStrategy.displayingUsers(with: $0, ownerRtmUUID: ownerRtmUUID) }
            .asDriver(onErrorJustReturn: [])
    }()
    
    let commandEncoder = CommandEncoder()
    let commandDecoder = CommandDecoder()
    
    struct TeacherOperationOutPut {
        let taps: Driver<Void>
        let starting: Driver<Bool>
        let pausing: Driver<Bool>
        let resuming: Driver<Bool>
        let stopping: Driver<Bool>
    }
    
    // MARK: - Public
    func transform(_ input: Input) -> Output {
        let initRoom = Driver.of(input.trigger, input.enterForeground)
            .merge()
            .asObservable()
            .flatMapLatest({ [unowned self] _ -> Observable<Void> in
                print("start init room")
                return self.initialRoomStatus().asObservable()
            })
            .share(replay: 1, scope: .whileConnected)
        
        let leaveRoomTemporary = input.enterBackground
            .asObservable()
            .flatMap { [unowned self] _ -> Observable<Void> in
                print("leave room temp")
                return self.leaveRoomProcess().asObservable()
            }
            .share(replay: 1, scope: .whileConnected)
        
        // Process member left
        let memberLeft = initRoom.flatMap { [weak self] _ -> Observable<String> in
            guard let self = self else { return .error("self not exist") }
            return self.commandHandler.memberLeftPublisher.asObservable()
        }.do(onNext: { [weak self] uuid in
            self?.state.removeUser(forUUID: uuid)
        })
        
        // Process command, include p2p command && channel command
        let newCommand = initRoom.flatMap { [weak self] _ -> Observable<(text: String, sender: String)> in
            guard let self = self else { return .error("self not exist") }
            let p2p = self.rtm.p2pMessage.asObservable()
            let channel = self.commandHandler.newMessagePublish.asObservable()
            return Observable.of(p2p, channel).merge()
        }.flatMap { [weak self] (text, sender) -> Single<RtmCommand> in
            guard let self = self else {
                return .error("self not exist")
            }
            print("receive command", text, sender)
            return self.processCommandMessage(text: text, senderId: sender)
        }.asObservable()
        
        // Do not have do any leave process for rtm is in error
        let roomError = rtm.error.map {
            $0.localizedDescription
        }
            .share(replay: 1, scope: .whileConnected)
        
        let roomStopped = state.startStatus
            .filter { $0 == .Stopped }
            .take(1)
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        return .init(initRoom: initRoom,
                     leaveRoomTemporary: leaveRoomTemporary,
                     newCommand: newCommand,
                     memberLeft: memberLeft,
                     roomStopped: roomStopped,
                     roomError: roomError)
    }
    
    func transformRaiseHand(_ raiseHandTap: Driver<Void>) -> Driver<Void> {
        let raiseHandTap = raiseHandTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.oppositeRaisingHand().asDriver(onErrorJustReturn: ())
        }
        
        return raiseHandTap
    }
    
    func transformSetting(_ input: SettingInput) -> SettingOutput {
        let selfCameraTap = input.cameraTap.flatMapLatest { [unowned self] in
            self.oppositeCameraFor(self.userUUID).asDriver(onErrorJustReturn: ())
        }
        
        let selfMicTap = input.micTap.flatMapLatest { [unowned self] in
            self.oppositeMicFor(self.userUUID).asDriver(onErrorJustReturn: ())
        }
        
        
        let studentAlert = AlertModel(title: NSLocalizedString("Class exit confirming title", comment: ""),
                                      message: NSLocalizedString("Class exit confirming detail", comment: ""),
                                      preferredStyle: .actionSheet, actionModels: [
                                        .init(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: nil),
                                        .init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)])
        
        let teacherStartAlert = AlertModel(title: NSLocalizedString("Close options", comment: ""),
                                           message: NSLocalizedString("Teacher close class room alert detail", comment: ""),
                                           preferredStyle: .actionSheet, actionModels: [
                                             .init(title: NSLocalizedString("Leaving for now", comment: ""), style: .default, handler: nil),
                                             .init(title: NSLocalizedString("End the class", comment: ""), style: .destructive, handler: nil),
                                             .init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)])
        
        let dismiss = input.leaveTap.flatMap { [unowned self] source -> Driver<AlertModel.ActionModel> in
            let status = self.state.startStatus.value
            if status == .Idle {
                return .just(.empty)
            }
            if !self.isTeacher {
                return self.alertProvider.showActionSheet(with: studentAlert, source: source).asDriver(onErrorJustReturn: .empty)
            }
            return self.alertProvider.showActionSheet(with: teacherStartAlert, source: source).asDriver(onErrorJustReturn: .empty)
        }.flatMap { model -> Driver<Bool> in
            if model.style == .cancel { return .just(false) }
            if model.style == .destructive {
                return self
                    .stopOperation()
                    .asDriver(onErrorJustReturn: ())
                    .map { _ -> Bool in
                        return true
                    }
            } else {
                return self
                    .leaveRoomProcess()
                    .asDriver(onErrorJustReturn: ())
                    .map { _ -> Bool
                        in return true
                    }
            }
        }

        let deviceTask = Driver.of(selfCameraTap, selfMicTap)
            .merge()
        return .init(deviceTask: deviceTask,
                     dismiss: dismiss)
    }
    
    func transformUserListInput(_ input: UserListInput) -> Driver<Void> {
        let stopInteractingTask = input.stopInteractingTap.flatMapLatest { [unowned self] in
            self.stopInteracting().asDriver(onErrorJustReturn: ())
        }
        
        let someUserCameraTap = input.tapSomeUserCamera.flatMapLatest { [unowned self] user in
            self.oppositeCameraFor(user.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        
        let someUserMicTap = input.tapSomeUserMic.flatMapLatest { [unowned self] user in
            self.oppositeMicFor(user.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        
        let someUserRaiseHandTap = input.tapSomeUserRaiseHand.flatMapLatest { [unowned self] user in
            self.acceptRaiseHand(forUUID: user.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        
        let someUserDisconnectTap = input.disconnectTap.flatMapLatest { [unowned self] user in
            self.disconnect(user.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        
        return Driver.of(stopInteractingTask,
                         someUserMicTap,
                         someUserCameraTap,
                         someUserRaiseHandTap,
                         someUserDisconnectTap)
            .merge()
    }
    
    func transform(localUserCameraTap: Driver<Void>,
                   localUserMicTap: Driver<Void>) -> Driver<Void> {
        let uuid = self.userUUID
        let camera = localUserCameraTap.flatMap {
            self.oppositeCameraFor(uuid).asDriver(onErrorJustReturn: ())
        }
        let mic = localUserMicTap.flatMap {
            self.oppositeMicFor(uuid).asDriver(onErrorJustReturn: ())
        }
        return Driver.of(camera, mic).merge()
    }
    
    func tranform(banTap: Driver<Void>) -> Driver<Void> {
        banTap.flatMap { [unowned self] _ -> Driver<Void> in
            let ban = !self.state.messageBan.value
            return self.sendCommand(.banText(ban), toTargetUID: nil)
                .asDriver(onErrorJustReturn: ())
                .do(onNext: { [weak self] in
                    self?.state.messageBan.accept(ban)
                })
        }
    }
    
    // MARK: - Teacher Operations
    func startOperation() -> Single<Void> {
        let api = RoomStatusUpdateRequest(newStatus: .Started, roomUUID: state.roomUUID)
        return ApiProvider.shared.request(fromApi: api)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                return self.sendCommand(.roomStartStatus(.Started), toTargetUID: nil)
            }
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                return self.sendCommand(.classRoomMode(.lecture), toTargetUID: nil)
            }
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self, let user = self.currentUser() else {
                    return .error("self not exist")
                }
                if !user.status.mic {
                    return self.oppositeMicFor(user.rtmUUID)
                } else {
                    return .just(())
                }
            }.asSingle()
            .do(onSuccess: { [weak self] in
                self?.state.startStatus.accept(.Started)
            })
    }
    
    func pauseOperation() -> Single<Void> {
        let api = RoomStatusUpdateRequest(newStatus: .Paused, roomUUID: state.roomUUID)
        return ApiProvider.shared.request(fromApi: api)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                return self.sendCommand(.roomStartStatus(.Paused), toTargetUID: nil)
            }
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self, let user = self.currentUser() else {
                    return .error("self not exist")
                }
                if user.status.mic {
                    return self.oppositeMicFor(user.rtmUUID)
                } else {
                    return .just(())
                }
            }.asSingle()
            .do(onSuccess: { [weak self] in
                self?.state.startStatus.accept(.Paused)
            })
    }
    
    func stopOperation() -> Single<Void> {
        let api = RoomStatusUpdateRequest(newStatus: .Stopped, roomUUID: state.roomUUID)
        return ApiProvider.shared.request(fromApi: api)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                return self.sendCommand(.roomStartStatus(.Stopped), toTargetUID: nil)
            }
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self, let user = self.currentUser() else {
                    return .error("self not exist")
                }
                if user.status.mic {
                    return self.oppositeMicFor(user.rtmUUID)
                } else {
                    return .just(())
                }
            }.asSingle()
            .do(onSuccess: { [weak self] in
                self?.state.startStatus.accept(.Stopped)
            }, onError: { [weak self] error in
                print("stop room error, \(error)")
                // Re trigger the stop operation
                if let status = self?.state.startStatus.value, status == .Stopped {
                    self?.state.startStatus.accept(.Stopped)
                }
            })
    }
    
    func resumeOperation() -> Single<Void> { startOperation() }
    
    // MARK: - Actions
    func stopInteracting() -> Single<Void> {
        guard isTeacher else {
            return .just(())
        }
        let users = state.users.value
        let speakingUsers = users.filter{ $0.status.isSpeak }
        let raisingHandUsers = users.filter{ $0.status.isRaisingHand }
        var task: Single<Void>!
        
        if !raisingHandUsers.isEmpty {
            task = self.sendCommand(.cancelRaiseHand(true), toTargetUID: nil)
        }
        if !speakingUsers.isEmpty {
            let commands = speakingUsers.map { SpeakCommand.init(userUUID: $0.rtmUUID, speak: false)}
            let speakTask = sendCommand(.speak(commands), toTargetUID: nil)
            if let existTask = task {
                task = existTask.flatMap { speakTask }
            } else {
                task = speakTask
            }
        }
        
        return task.do(onSuccess: { [weak self] in
            var processUsers: [RoomUser] = .init(raisingHandUsers)
            processUsers.append(contentsOf: speakingUsers)
            processUsers = processUsers.removeDuplicate()
            if !processUsers.isEmpty {
                for user in processUsers {
                    var status = user.status
                    status.isSpeak = false
                    status.isRaisingHand = false
                    self?.state.updateUserStatusFor(userRtmUID: user.rtmUUID, status: status)
                }
            }
        })
    }
    
    func disconnect(_ UUID: String) -> Single<Void> {
        let task = sendCommand(.speak([.init(userUUID: UUID, speak: false)]), toTargetUID: nil)
        return task.do(onSuccess: { [weak self] in
            guard var status = self?.state.userStatusFor(userUUID: UUID) else { return }
            status.isSpeak = false
            status.mic = false
            status.camera = false
            self?.state.updateUserStatusFor(userRtmUID: UUID, status: status)
        })
    }
    
    func oppositeRaisingHand() -> Single<Void> {
        guard let user = currentUser(), !isTeacher else {
            return .just(())
        }
        let raiseHand = !user.status.isRaisingHand
        return sendCommand(.raiseHand(raiseHand), toTargetUID: nil)
            .do(onSuccess: { [weak self] in
                guard var newStatus = self?.state.userStatusFor(userUUID: user.rtmUUID) else { return }
                newStatus.isRaisingHand = raiseHand
                self?.state.updateUserStatusFor(userRtmUID: user.rtmUUID, status: newStatus)
            })
    }
    
    func acceptRaiseHand(forUUID UUID: String) -> Single<Void> {
        guard isTeacher else { return .just(())}
        return sendCommand(.acceptRaiseHand(.init(userUUID: UUID, accept: true)), toTargetUID: nil)
            .do(onSuccess: { [weak self] in
                guard var status = self?.state.userStatusFor(userUUID: UUID) else { return }
                status.isRaisingHand = false
                status.isSpeak = true
                status.mic = true
                self?.state.updateUserStatusFor(userRtmUID: UUID, status: status)
            })
    }
    
    func oppositeCameraFor(_ userUUID: String) -> Single<Void> {
        guard var status = state.userStatusFor(userUUID: userUUID) else {
            return .error("user not exist")
        }
        if userUUID != self.userUUID {
            if !status.camera {
                return .error("can't open camera")
            } else if !isTeacher {
                // Only teacher can turn off others
                return .error("can't turn off others not teacher")
            }
        }
        status.camera = !status.camera
        return sendCommand(.deviceState(.init(userUUID: userUUID,
                                              camera: status.camera,
                                              mic: status.mic)),
                           toTargetUID: nil)
            .do(onSuccess: { [weak self] in
                self?.state.updateUserStatusFor(userRtmUID: userUUID,
                                                status: status)
            })
    }
    
    func oppositeMicFor(_ userUUID: String) -> Single<Void> {
        guard var status = state.userStatusFor(userUUID: userUUID) else {
            return .error("user not exist")
        }
        if userUUID != self.userUUID {
            if status.mic {
                // Only teacher can turn off others
                if !isTeacher {
                    return .error("can't turn off others not teacher")
                }
            } else {
                // Can't turn on mic
                return .error("can't open mic")
            }
        }
        status.mic = !status.mic
        return sendCommand(.deviceState(.init(userUUID: userUUID,
                                              camera: status.camera,
                                              mic: status.mic)),
                           toTargetUID: nil)
            .do(onSuccess: { [weak self] in
                self?.state.updateUserStatusFor(userRtmUID: userUUID,
                                                status: status)
            })
    }
    
    func processCommandMessage(text: String, senderId: String) -> Single<RtmCommand> {
        do {
            let command = try self.commandDecoder.decode(text)
            switch command {
            case .deviceState(let deviceStateCommand):
                guard var newStatus = state.userStatusFor(userUUID: deviceStateCommand.userUUID) else {
                    return .just(command)
                }
                newStatus.camera = deviceStateCommand.camera
                newStatus.mic = deviceStateCommand.mic
                state.updateUserStatusFor(userRtmUID: deviceStateCommand.userUUID, status: newStatus)
                return .just(command)
            case .requestChannelStatus(let requestChannelStatusCommand):
                // TODO: response is not reliable, should depend on the current status
                return respondToRequestChannelStatusCommand(requestChannelStatusCommand, fromUID: senderId).map { _ ->  RtmCommand in
                    return command
                }
            case .roomStartStatus(let status):
                state.startStatus.accept(status)
                return .just(command)
            case .channelStatus:
                // Process by initRoom
                return .just(command)
            case .raiseHand(let raiseHand):
                guard var status = state.userStatusFor(userUUID: senderId) else {
                    return .just(command)
                }
                status.isRaisingHand = raiseHand
                state.updateUserStatusFor(userRtmUID: senderId, status: status)
                return .just(command)
            case .acceptRaiseHand(let acceptCommand):
                guard var status = state.userStatusFor(userUUID: acceptCommand.userUUID) else {
                    return .just(command)
                }
                if acceptCommand.accept {
                    status.isRaisingHand = false
                    status.mic = true
                    status.isSpeak = true
                    state.updateUserStatusFor(userRtmUID: acceptCommand.userUUID, status: status)
                }
                return .just(command)
            case .cancelRaiseHand:
                let newUsers = state.users.value.map { user -> RoomUser in
                    var new = user
                    new.status.isRaisingHand = false
                    return new
                }
                state.users.accept(newUsers)
                return .just(command)
            case .banText(let ban):
                state.messageBan.accept(ban)
                return .just(command)
            case .speak(let speakCommand):
                for command in speakCommand {
                    if var status = state.userStatusFor(userUUID: command.userUUID) {
                        status.isSpeak = command.speak
                        status.mic = command.speak
                        status.camera = command.speak
                        state.updateUserStatusFor(userRtmUID: command.userUUID, status: status)
                    }
                }
                return .just(command)
            case .classRoomMode(let mode):
                state.mode.accept(mode)
                return .just(command)
            case .notice(let notice), .undefined(let notice):
                print("notice \(notice)")
                return .just(command)
            }
        }
        catch {
            let e = "decode command error \(error)"
            print(e)
            return .error(e)
        }
    }
    
    // MARK: - Private
    func initialRoomStatus() -> Single<Void> {
        rtm.login()
            .flatMap { [weak self] _ -> Single<AnyChannelHandler> in
                guard let self = self else{
                    return .error("self not exist")
                }
                return self.rtm.joinChannelId(self.commandChannelId)
            }.do(onSuccess: { [weak self] handler in self?.commandHandler = handler })
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else{
                    return .error("self not exist")
                }
                return self.requestRoomStatus()
            }.flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
                if self.isTeacher, self.state.startStatus.value == .Idle {
                    return self.startOperation()
                } else {
                    return .just(())
                }
            }
    }
    
    func requestRoomStatus() -> Single<Void> {
        let userId = self.userUUID
        let roomId = self.state.roomUUID
        
        return commandHandler.getMembers()
            .flatMap { [weak self] memberIds -> Single<Void> in
                guard let self = self else {
                    return .error("self not exist")
                }
                guard let randomId = memberIds.filter({ $0 != userId }).randomElement() else {
                    self.state.applyWithNoUser()
                    return .just(())
                }
                let users = ApiProvider.shared.request(fromApi: MemberRequest(roomUUID: roomId, usersUUID: memberIds))
                    .map { result -> [RoomUser] in
                        let users = result.response.map {
                            return RoomUser(rtmUUID: $0.key,
                                            rtcUID: $0.value.rtcUID,
                                            name: $0.value.name,
                                            avatarURL: $0.value.avatarURL)
                        }
                        return users
                    }
                    .do(onNext: { [weak self] users in
                        self?.state.appendUser(fromContentsOf: users)
                    }).asObservable()
                
                        // TODO: Fix for somebody not response
                let firstStatusCommand = self.rtm.p2pMessage
                        .map { (str, userId) -> ChannelStatusCommand? in
                            let command = try self.commandDecoder.decode(str)
                            if case .channelStatus(let status) = command {
                                return status
                            } else {
                                return nil
                            }
                        }
                        .skip(while: { $0 == nil })
                        .take(1)
                        .map { $0! }
                        .do(onNext: { [weak self] status in
                            let userStatus: [String: RoomUserStatus] = status.userStates.mapValues { str in
                                RoomUserStatus(string: str)
                            }
                            // Init room status
                            self?.state.initRoomStateFromOtherState(messageBan: status.banMessage,
                                                                    startStatus: status.roomStartStatus,
                                                                    roomMode: status.classRoomMode,
                                                                    userStatus: userStatus)
                        })
                
                let command = self.generateRequestStatusCommand(fromUUID: randomId)
                
                return users
                    .flatMap { [weak self] _ -> Single<Void> in
                        guard let self = self else {
                            return .error("self not exist")
                        }
                        return self.sendCommand(.requestChannelStatus(command), toTargetUID: nil)
                    }
                    .flatMap { firstStatusCommand }
                    .map { _ -> Void in return () }
                    .asSingle()
            }
    }
    
    func leaveRoomProcess() -> Single<Void> {
        rtm.leave()
    }
    
    // TODO: Update Mic / Camera before request
    func currentUser() -> RoomUser? {
        state.users.value.first(where: { $0.rtmUUID == userUUID })
    }
    
    func respondToRequestChannelStatusCommand(_ command: RequestChannelStatusCommand, fromUID uid: String) -> Single<Void> {
        let userValue = ApiProvider.shared.request(fromApi: MemberRequest(roomUUID: state.roomUUID,
                                                                          usersUUID: [uid]))
            .map {
                let user = ($0.response.first?.value)!
                let userStatus = RoomUserStatus(isSpeak: command.user.isSpeak,
                                                isRaisingHand: false,
                                                camera: command.user.camera,
                                                mic: command.user.mic)
                return RoomUser(rtmUUID: uid,
                                rtcUID: user.rtcUID,
                                name: user.name,
                                avatarURL: user.avatarURL,
                                status: userStatus)
            }
            .do(onNext: { [weak self] user in
                self?.state.appendUser(user)
            })
                
        let result = userValue.flatMap { [weak self] user -> Single<Void> in
            guard let self = self else {
                return .error("self not exist")
            }
            // Respond channel status when userUUID list contains self
            guard command.userUUIDs.contains(self.userUUID) else {
                return .just(())
            }
            // Send the recent user list to the new coming
            var userStates: [String: String] = [:]
            for user in self.state.users.value {
                let uuid = user.rtmUUID
                let statusString = user.status.toString()
                userStates[uuid] = statusString
            }
            // Generate the response
            let statusCommands = ChannelStatusCommand(banMessage: self.state.messageBan.value,
                                                      roomStartStatus: self.state.startStatus.value,
                                                      classRoomMode: self.state.mode.value,
                                                      userStates: userStates)
            return self.sendCommand(.channelStatus(statusCommands), toTargetUID: uid)
        }
        return result.asSingle()
    }
    
    func generateRequestStatusCommand(fromUUID UUID: String) -> RequestChannelStatusCommand {
        let currentUser = currentUser()!
        return RequestChannelStatusCommand(roomUUID: state.roomUUID,
                                           userUUIDs: [UUID],
                                           user: .init(name: currentUser.name,
                                                       camera: currentUser.status.camera,
                                                       mic: currentUser.status.mic,
                                                       isSpeak: currentUser.status.isSpeak))
    }
    
    func sendCommand(_ command: RtmCommand,
                     toTargetUID targetId: String?) -> Single<Void> {
        let channelId = self.commandHandler.channelId
        do {
            if let targetId = targetId {
                let str = try commandEncoder.encode(command, withChannelId: channelId)
                print("send command \(str), to \(targetId)")
                return self.rtm.sendMessage(text: str, toUUID: targetId)
            } else {
                let str = try commandEncoder.encode(command, withChannelId: nil)
                return commandHandler.sendMessage(str)
            }
        }
        catch {
            return .error("create command error \(error)")
        }
    }
}
