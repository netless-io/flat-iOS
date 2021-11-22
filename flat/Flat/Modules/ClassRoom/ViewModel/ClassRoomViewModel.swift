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

let classStopNotification = Notification.Name("classStopNotification")

class ClassRoomViewModel {
    struct Input {
        let trigger: Driver<Void>
    }
    
    struct Output {
        let initRoom: Single<Void>
        let newCommand: Observable<RtmCommand>
        let memberLeft: Observable<String>
        let roomStopped: Driver<Void>
    }
    
    struct TeacherOperationInput {
        let startTap: Driver<Void>
        let resumeTap: Driver<Void>
        let endTap: Driver<Void>
        let pauseTap: Driver<Void>
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
    
    var didTeacherShow: Driver<Bool> {
        let ownerRtmUUID = state.roomOwnerRtmUUID
        return state.users.asDriver()
            .map { users -> Bool in
                users.contains(where: { $0.rtmUUID == ownerRtmUUID })
            }
    }
    
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
            .map { type.rtcStrategy.displayingUsers(with: $0, ownnerRtmUUID: ownerRtmUUID) }
            .asDriver(onErrorJustReturn: [])
    }()
    
    let commandEncoder = CommandEncoder()
    let commandDecoder = CommandDecoder()
    
    // MARK: - Public
    func tranfromTeacherInput(_ input: TeacherOperationInput) -> Driver<Void> {
        let startTap = input.startTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.startOperation().asDriver(onErrorJustReturn: ())
        }
        
        let pauseTap = input.pauseTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.pauseOperation().asDriver(onErrorJustReturn: ())
        }
        
        let resumeTap = input.resumeTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.resumeOperation().asDriver(onErrorJustReturn: ())
        }
        
        let stopTap = input.endTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.alertProvider.showAlert(with: .init(title: "确认结束上课？",
                                                     message: "一旦结束上课，所有用户退出房间，并且自动结束课程和录制（如有），不能继续直播",
                                                     preferredStyle: .alert,
                                                     actionModels: [.cancel, .comfirm]))
                .filter { $0.title == AlertModel.ActionModel.comfirm.title }
                .flatMap { [unowned self] _ -> Maybe<Void> in
                    self.stopOperation().asMaybe()
                }
                .asDriver(onErrorJustReturn: ())
        }
        
        return Driver.of(startTap, pauseTap, resumeTap, stopTap).merge()
    }
    
    func transform(_ input: Input) -> Output {
        let initRoom = input.trigger.asObservable().flatMapLatest { [unowned self] in
            self.initialRoomStatus()
        }.share(replay: 1, scope: .whileConnected).asSingle()
        
        // Process member left
        let memberLeft = initRoom.asObservable().flatMap { [weak self] _ -> Observable<String> in
            guard let self = self else { return .error("self not exist") }
            return self.commandHandler.memberLeftPublisher.asObservable()
        }.do(onNext: { [weak self] uuid in
            self?.state.removeUser(forUUID: uuid)
        })
        
        // Process command, include p2pcommand && channel command
        let newCommand = initRoom.asObservable().flatMap { [weak self] _ -> Observable<(text: String, sender: String)> in
            guard let self = self else { return .error("self not exist") }
            let p2p = self.rtm.p2pMessage.asObservable()
            let channel = self.commandHandler.newMessagePublish.asObservable()
            return Observable.of(p2p, channel).merge()
        }.flatMap { [weak self] (text, sender) -> Single<RtmCommand> in
            guard let self = self else {
                return .error("self not exist")
            }
            print("receive comand", text, sender)
            return self.processCommandMessage(text: text, senderId: sender)
        }.asObservable()
        
        let roomStopped = state.startStatus
            .filter { $0 == .Stopped }
            .take(1)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exits") }
                return self.leaveRoomProcess()
            }
            .asSingle()
            .do(onSuccess: { [weak self] in
                NotificationCenter.default.post(name: classStopNotification,
                                                object: nil,
                                                userInfo: ["classRoomUUID": self?.state.roomUUID ?? ""])
            })
            .asDriver(onErrorJustReturn: ())
        
        return .init(initRoom: initRoom,
                     newCommand: newCommand,
                     memberLeft: memberLeft,
                     roomStopped: roomStopped)
    }
    
    func transformRaiseHand(_ raiseHandTap: Driver<Void>) -> Driver<Void> {
        let raiseHandTap = raiseHandTap.flatMap { [unowned self] _ -> Driver<Void> in
            return self.oppositeraiseHand().asDriver(onErrorJustReturn: ())
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
        
        
        let studentAlert = AlertModel(title: "确认退出房间？",
                                      message: "课堂正在继续，确定退出房间",
                                      preferredStyle: .actionSheet, actionModels: [
                                        .init(title: "确认退出", style: .destructive, handler: nil),
                                        .init(title: "取消退出", style: .cancel, handler: nil)])
        
        let teacherStartAlert = AlertModel(title: "关闭选项",
                                           message: "课堂正在继续，你是暂时离开还是结束上课？",
                                           preferredStyle: .actionSheet, actionModels: [
                                             .init(title: "暂时离开", style: .default, handler: nil),
                                             .init(title: "结束上课", style: .destructive, handler: nil),
                                             .init(title: "取消退出", style: .cancel, handler: nil)])
        
        let dismiss = input.leaveTap.flatMap { [unowned self] source -> Driver<AlertModel.ActionModel> in
            let status = self.state.startStatus.value
            if status == .Idle {
                return .just(.emtpy)
            }
            if !self.isTeacher {
                return self.alertProvider.showAcionSheet(with: studentAlert, source: source).asDriver(onErrorJustReturn: .emtpy)
            }
            return self.alertProvider.showAcionSheet(with: teacherStartAlert, source: source).asDriver(onErrorJustReturn: .emtpy)
        }.flatMap { model -> Driver<Bool> in
            if model.style == .cancel { return .just(false) }
            if model.title == "结束上课" {
                return self.stopOperation().flatMap { [weak self] in
                    guard let self = self else { return .just(()) }
                    return self.leaveRoomProcess()
                }.asDriver(onErrorJustReturn: ()).map { _ -> Bool in return true }
            } else {
                return self.leaveRoomProcess().asDriver(onErrorJustReturn: ()).map { _ -> Bool in return true }
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
            self.disconect(user.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        
        return Driver.of(stopInteractingTask,
                         someUserMicTap,
                         someUserCameraTap,
                         someUserRaiseHandTap,
                         someUserDisconnectTap)
            .merge()
    }
    
    func transform(rtcCameraTap: Driver<RoomUser>,
                   rtcMicTap: Driver<RoomUser>) -> Driver<Void> {
        let camera = rtcCameraTap.flatMap {
            self.oppositeCameraFor($0.rtmUUID).asDriver(onErrorJustReturn: ())
        }
        let mic = rtcMicTap.flatMap {
            self.oppositeMicFor($0.rtmUUID).asDriver(onErrorJustReturn: ())
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
    
    func disconect(_ UUID: String) -> Single<Void> {
        let task = sendCommand(.speak([.init(userUUID: UUID, speak: false)]), toTargetUID: nil)
        return task.do(onSuccess: { [weak self] in
            guard var status = self?.state.userStatusFor(userUUID: UUID) else { return }
            status.isSpeak = false
            status.mic = false
            status.camera = false
            self?.state.updateUserStatusFor(userRtmUID: UUID, status: status)
        })
    }
    
    func oppositeraiseHand() -> Single<Void> {
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
        return sendCommand(.accpetRaiseHand(.init(userUUID: UUID, accept: true)), toTargetUID: nil)
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
        if userUUID != self.userUUID, !status.camera {
            return .error("can't open camera")
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
        if userUUID != self.userUUID, !status.mic {
            return .error("can't open mic")
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
                return respondToReqeustChannelStatusCommand(requestChannelStatusCommand, fromUID: senderId).map { _ ->  RtmCommand in
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
            case .accpetRaiseHand(let accpetCommand):
                guard var status = state.userStatusFor(userUUID: accpetCommand.userUUID) else {
                    return .just(command)
                }
                if accpetCommand.accept {
                    status.isRaisingHand = false
                    status.mic = true
                    status.isSpeak = true
                    state.updateUserStatusFor(userRtmUID: accpetCommand.userUUID, status: status)
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
                        return self.sendCommand(.requestChannelStatus(command), toTargetUID: randomId)
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
    
    func respondToReqeustChannelStatusCommand(_ command: RequestChannelStatusCommand, fromUID uid: String) -> Single<Void> {
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
            // Send the recent user list to the new comming
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
