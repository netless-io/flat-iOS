//
//  ClassRoomViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class ClassRoomViewModel {
    private var stateHandler: ClassroomStateHandler!

    let preferredDeviceState: DeviceState
    let alertProvider: AlertProvider
    let rtm: Rtm
    let commandChannelRequest: Single<RtmChannel>
    let userUUID: String
    let roomUUID: String
    let isOwner: Bool
    let roomType: ClassRoomType
    let initDeviceState: DeviceState
    var banState: Observable<Bool> { stateHandler.banState.asObservable() }
    var members: Observable<[RoomUser]> { stateHandler.members() }
    var onStageUsers: Observable<[RoomUser]> {
        members
            .map { users in
                users.filter(\.status.isSpeak)
            }
    }

    var currentUser: Observable<RoomUser> {
        members
            .map { [weak self] m in
                guard let self else { throw "self not exist" }
                return m.first(where: { $0.rtmUUID == self.userUUID }) ?? .empty
            }
            .distinctUntilChanged()
    }

    func transWhiteboardPermissionUpdate(whiteboardEnable: Observable<Bool>) -> Driver<String> {
        currentUser
            .map(\.status.whiteboard)
            .distinctUntilChanged()
            .skip(1)
            .map {
                $0 ? localizeStrings("WhiteboardPermissionOpenToast") : localizeStrings("WhiteboardPermissionCloseToast")
            }
            .asDriver(onErrorJustReturn: "")
    }

    // Show tips when user's whiteboard permission is ready
    func transOnStageUpdate(whiteboardEnable: Observable<Bool>) -> Observable<String> {
        Observable
            .combineLatest(
                currentUser.map(\.status.isSpeak),
                whiteboardEnable) { speak, whiteboard -> (speak: Bool, whiteboard: Bool) in (speak, whiteboard) }
            .filter { ($0.speak && $0.whiteboard) || !$0.speak }
            .map(\.speak)
            .distinctUntilChanged()
            .skip(1)
            .flatMap { [weak self] speak -> Observable<String> in
                guard let self else { return .error("self not exist") }
                if speak {
                    let micOn = self.preferredDeviceState.mic
                    return self.stateHandler
                        .send(command: .updateDeviceState(uuid: self.userUUID, state: self.preferredDeviceState))
                        .asObservable()
                        .map { _ -> String in
                            micOn ? localizeStrings("onStageTips") : localizeStrings("onStageNoMicTips")
                        }
                } else {
                    return .just(localizeStrings("onOffStageTips"))
                }
            }
    }

    var raiseHandHide: Observable<Bool> {
        Observable.combineLatest(currentUser,
                                 banState) { [weak self] currentUser, ban in
            guard let self else { return true }
            if self.isOwner { return true }
            if ban { return true }
            return currentUser.status.isSpeak
        }
    }

    var whiteboardPermission: Observable<WhiteboardPermission> { currentUser.map { .init(writable: $0.status.whiteboard || $0.status.isSpeak, inputEnable: $0.status.whiteboard) }}

    var isRaisingHand: Observable<Bool> {
        currentUser.map(\.status.isRaisingHand)
    }

    var roomStoped: Observable<Void> {
        stateHandler.roomStartStatus
            .filter { $0 == .Stopped }
            .mapToVoid()
            .asObservable()
    }

    var showUsersResPoint: Observable<Bool> {
        members
            .map { users -> Bool in
                users.contains(where: \.status.isRaisingHand)
            }
    }

    init(stateHandler: ClassroomStateHandler,
         initDeviceState: DeviceState,
         isOwner: Bool,
         userUUID: String,
         roomUUID: String,
         roomType: ClassRoomType,
         commandChannelRequest: Single<RtmChannel>,
         rtm: Rtm,
         alertProvider: AlertProvider,
         preferredDeviceState: DeviceState)
    {
        self.stateHandler = stateHandler
        self.initDeviceState = initDeviceState
        self.isOwner = isOwner
        self.userUUID = userUUID
        self.roomUUID = roomUUID
        self.roomType = roomType
        self.commandChannelRequest = commandChannelRequest
        self.rtm = rtm
        self.alertProvider = alertProvider
        self.preferredDeviceState = preferredDeviceState
    }

    struct InitRoomOutput {
        let initRoomResult: Single<Void>
        let roomError: Observable<ClassroomStateError>
        /// enable when user is an owner and roomType is oneToOne
        let autoPickMemberOnStageOnce: Single<RoomUser?>?
    }

    func initialRoomStatus() -> InitRoomOutput {
        let initRoom = stateHandler.setup()
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self else { return .error("self not exist") }
                // Owner broadcast state when join room
                if self.isOwner {
                    return self.stateHandler.send(command: .updateDeviceState(uuid: self.userUUID, state: self.initDeviceState))
                } else {
                    return .just(())
                }
            }

        let shareInitRoom = initRoom
            .asObservable()
            .share(replay: 1, scope: .whileConnected)

        let autoPickMemberOnStageOnce: Single<RoomUser?>?
        if roomType == .oneToOne, isOwner {
            autoPickMemberOnStageOnce = shareInitRoom
                .flatMap { [weak self] _ -> Observable<[RoomUser]> in
                    guard let self else { return .error("self not exist") }
                    return self.members
                }
                .skip(while: { $0.count < 2 })
                .take(1)
                .flatMap { [weak self] members -> Observable<RoomUser?> in
                    guard let self else { return .error("self not exist") }
                    let speakers = members.filter(\.status.isSpeak)
                    if speakers.count >= 2 {
                        return .just(nil)
                    }

                    let nonSpeakers = members.filter {
                        $0.rtmUUID != self.userUUID &&
                            !$0.status.isSpeak
                    }
                    if let target = nonSpeakers.first {
                        return self.stateHandler
                            .send(command: .pickUserOnStage(target.rtmUUID))
                            .asObservable()
                            .map { target }
                    } else {
                        return .just(nil)
                    }
                }
                .asSingle()
        } else {
            autoPickMemberOnStageOnce = nil
        }

        let error = stateHandler.error.asObservable()

        return .init(initRoomResult: shareInitRoom.asSingle(), roomError: error, autoPickMemberOnStageOnce: autoPickMemberOnStageOnce)
    }

    struct ChatChannelInitValue {
        let channel: RtmChannel
        let userNameProvider: UserInfoQueryProvider
        let notice: Observable<String>
        let isBanned: Driver<Bool>
        let banMessagePublisher: PublishRelay<Bool>
        let chatButtonShowRedPoint: Driver<Bool>
    }

    struct ChatInput {
        let chatButtonTap: ControlEvent<Void>
        let chatControllerPresentedFetch: () -> Driver<Bool>
    }

    func initChatChannel(_ input: ChatInput) -> Single<ChatChannelInitValue> {
        let channel = commandChannelRequest
            .asObservable()
            .share(replay: 1, scope: .forever)

        let provider = stateHandler.memberNameQueryProvider()
        let isBanned = banState.asDriver(onErrorJustReturn: true)
        let notice = stateHandler.noticePublisher.asObservable()
        let banMessagePublisher = stateHandler.banMessagePublisher

        let newMessageWhenChatControllerHide = channel
            .flatMap { channel -> Observable<Void> in
                channel.newMessagePublish.asObservable().mapToVoid()
            }
            .flatMap { _ -> Observable<Bool> in
                input.chatControllerPresentedFetch().asObservable()
            }
            .map { !$0 }
            .asDriver(onErrorJustReturn: false)
        let tapChat = input.chatButtonTap.map { false }.asDriver(onErrorJustReturn: false)

        let chatButtonShowRedPoint = Driver.of(newMessageWhenChatControllerHide, tapChat)
            .merge()

        return channel.asSingle()
            .map { channel -> ChatChannelInitValue in
                .init(channel: channel,
                      userNameProvider: provider,
                      notice: notice,
                      isBanned: isBanned,
                      banMessagePublisher: banMessagePublisher,
                      chatButtonShowRedPoint: chatButtonShowRedPoint)
            }
    }

    func transformBanClick(_ input: ControlEvent<Void>) -> Observable<Bool> {
        input
            .withLatestFrom(stateHandler.banState, resultSelector: { _, ban in !ban })
            .flatMap { [weak self] ban -> Observable<Bool> in
                guard let self else { return .error("self not exist") }
                return self.stateHandler.send(command: .ban(ban))
                    .asObservable()
                    .map { ban }
            }
    }
    
    func observableRewards() -> Observable<UInt> {
        stateHandler.rewardPublisher
            .withLatestFrom(members, resultSelector: { uuid, members in
                members.first(where: { $0.rtmUUID == uuid })?.rtcUID
            })
            .filter({ $0 != nil })
            .map { $0! }
            .asObservable()
    }

    func transformRaiseHandClick(_ input: ControlEvent<Void>) -> Driver<Bool> {
        guard !isOwner else { return .just(false) }
        return input
            .throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
            .withLatestFrom(currentUser) { _, user in
                user.status
            }
            .asDriver(onErrorJustReturn: .default)
            .flatMap { [weak self] status -> Driver<Bool> in
                guard let self else { return .just(false) }
                if status.isSpeak { return .just(false) }
                return self.stateHandler
                    .send(command: .updateRaiseHand(!status.isRaisingHand))
                    .asDriver(onErrorJustReturn: ())
                    .map { !status.isRaisingHand }
            }
    }

    func listeningDeviceNotifyOff() -> Driver<String> {
        stateHandler.notifyDeviceOffPublisher
            .map { type -> String in
                switch type {
                case .camera:
                    return localizeStrings("TeacherTurnOffCamera")
                case .mic:
                    return localizeStrings("TeacherTurnOffMic")
                }
            }
            .asDriver(onErrorJustReturn: "")
    }

    func listeningDeviceResponse() -> Driver<String> {
        stateHandler.requestDeviceResponsePublisher
            .map(\.toast)
            .asDriver(onErrorJustReturn: "")
    }

    func listeningDeviceRequest() -> Driver<Void> {
        let micAlert = AlertModel(title: localizeStrings("Alert"),
                                  message: localizeStrings("TeacherRequestMic"),
                                  preferredStyle: .alert,
                                  actionModels: [.init(title: localizeStrings("Agree"), style: .default),
                                                 .init(title: localizeStrings("Reject"), style: .cancel)])
        let cameraAlert = AlertModel(title: localizeStrings("Alert"),
                                     message: localizeStrings("TeacherRequestCamera"),
                                     preferredStyle: .alert,
                                     actionModels: [.init(title: localizeStrings("Agree"), style: .default),
                                                    .init(title: localizeStrings("Reject"), style: .cancel)])
        return stateHandler
            .requestDevicePublisher
            .asObservable()
            .flatMap { [weak self] type -> Observable<(RequestDeviceType, Bool)?> in
                guard let self else { return .error("self not exist") }
                switch type {
                case .camera:
                    return self.alertProvider
                        .showAlert(with: cameraAlert, tag: "requestCamera")
                        .map { model in
                            if let model {
                                return (.camera, model.style == .default)
                            }
                            return nil
                        }
                        .asObservable()
                case .mic:
                    return self.alertProvider
                        .showAlert(with: micAlert, tag: "requestMic")
                        .map { model in
                            if let model {
                                return (.mic, model.style == .default)
                            }
                            return nil
                        }
                        .asObservable()
                }
            }
            .flatMap { [weak self] deviceRequest -> Observable<Void> in
                guard let (type, isOn) = deviceRequest else { return .just(()) }
                guard let self else { return .error("self not exist") }
                let responseCommand = self.stateHandler
                    .send(command: .requestDeviceResponse(type: type, on: isOn))
                    .asObservable()
                if isOn {
                    return responseCommand
                        .flatMap { [weak self] _ -> Observable<RoomUser> in
                            guard let self else { return .error("self not exist") }
                            return self.currentUser.take(1)
                        }.flatMap { [weak self] user -> Observable<Void> in
                            guard let self else { return .error("self not exist") }
                            switch type {
                            case .camera:
                                return self.stateHandler
                                    .send(command: .updateDeviceState(uuid: self.userUUID, state: .init(mic: user.status.mic, camera: true)))
                                    .asObservable()
                            case .mic:
                                return self.stateHandler
                                    .send(command: .updateDeviceState(uuid: self.userUUID, state: .init(mic: true, camera: user.status.camera)))
                                    .asObservable()
                            }
                        }
                }
                return responseCommand
            }
            .asDriver(onErrorJustReturn: ())
    }

    struct UserListInput {
        let allMuteTap: Observable<Void>
        let stopInteractingTap: Observable<Void>
        let tapSomeUserOnStage: Observable<RoomUser>
        let tapSomeUserWhiteboard: Observable<RoomUser>
        let tapSomeUserRaiseHand: Observable<RoomUser>
        let tapSomeUserCamera: Observable<String>
        let tapSomeUserMic: Observable<String>
        let tapSomeUserReward: Observable<String>
    }

    func transformUserListInput(_ input: UserListInput) -> Driver<String> {
        let allMuteTask = input.allMuteTap
            .flatMap { [unowned self] _ -> Single<String> in
                guard self.isOwner else { return .just("") }
                return self.stateHandler
                    .send(command: .allMute)
                    .map { localizeStrings("All mute toast") }
            }.asDriver(onErrorJustReturn: "all mute task error")
        
        let rewardTask = input.tapSomeUserReward
            .flatMap { [unowned self] userUUID -> Single<String> in
                guard self.isOwner else { return .just("") }
                return self.stateHandler
                    .send(command: .sendReward(toUserUUID: userUUID))
                    .map { "" }
            }.asDriver(onErrorJustReturn: "all mute task error")

        let stopTask = input.stopInteractingTap
            .flatMap { [unowned self] _ -> Single<String> in
                guard self.isOwner else { return .just("") }
                return self.stateHandler
                    .send(command: .stopInteraction)
                    .map { "" }
            }.asDriver(onErrorJustReturn: "stop interaction error")

        let onStageTask = Observable.merge(input.tapSomeUserRaiseHand, input.tapSomeUserOnStage)
            .flatMap { [unowned self] user -> Single<String> in
                if user.status.isSpeak {
                    if user.rtmUUID == self.userUUID || self.isOwner {
                        return self.stateHandler
                            .send(command: .disconnectUser(user.rtmUUID))
                            .map { "" }
                    }
                } else {
                    if self.isOwner {
                        let isSmallClass = self.roomType == .smallClass
                        return self.stateHandler.checkIfSpeakUserOverMaxCount()
                            .flatMap { overCount in
                                if overCount {
                                    return .just(localizeStrings(isSmallClass ? "MaxWritableUsersTipsForSmallClass" : "MaxWritableUsersTips"))
                                }
                                return self.stateHandler
                                    .send(command: .pickUserOnStage(user.rtmUUID))
                                    .map { "" }
                            }
                    }
                }
                return .just("")
            }.asDriver(onErrorJustReturn: "stage task error")

        let cancelRaiseHandTask = input.tapSomeUserRaiseHand
            .filter { [unowned self] in $0.rtmUUID == self.userUUID && $0.status.isRaisingHand }
            .flatMap { [unowned self] _ in self.stateHandler.send(command: .updateRaiseHand(false)) }
            .map { _ in "" }
            .asDriver(onErrorJustReturn: "")

        let whiteboardTask = input.tapSomeUserWhiteboard
            .flatMap { [unowned self] user -> Single<String> in
                if user.status.whiteboard {
                    if user.rtmUUID == self.userUUID || self.isOwner {
                        return self.stateHandler
                            .send(command: .updateUserWhiteboardEnable(uuid: user.rtmUUID, enable: false))
                            .map { "" }
                    }
                } else {
                    if self.isOwner {
                        return self.stateHandler
                            .send(command: .updateUserWhiteboardEnable(uuid: user.rtmUUID, enable: true))
                            .map { "" }
                    }
                }
                return .just("")
            }.asDriver(onErrorJustReturn: "whiteboard task error")

        let cameraTask = input
            .tapSomeUserCamera
            .withLatestFrom(onStageUsers) { uuid, users in
                users.first(where: { $0.rtmUUID == uuid })
            }.flatMap { [unowned self] user -> Single<String> in
                guard let user else { return .error("User not found") }
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just("") }
                let newDeviceState = DeviceState(mic: user.status.mic, camera: !user.status.camera)
                let command = ClassroomCommand.updateDeviceState(uuid: user.rtmUUID, state: newDeviceState)
                let sending = self.stateHandler.send(command: command)
                    .map { [weak self] _ -> String in
                        guard let self else { return "" }
                        if user.rtmUUID != self.userUUID, !user.status.deviceState.camera { // Toast for send device request
                            return localizeStrings("SentInvitation")
                        }
                        return ""
                    }
                    .catch { error in
                        return .just(error.localizedDescription)
                    }
                return sending
            }.asDriver(onErrorJustReturn: "Camera task error")

        let micTask = input
            .tapSomeUserMic
            .withLatestFrom(onStageUsers) { uuid, users in
                users.first(where: { $0.rtmUUID == uuid })
            }.flatMap { [unowned self] user -> Single<String> in
                guard let user else { return .error("User not found") }
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just("") }
                let newDeviceState = DeviceState(mic: !user.status.mic, camera: user.status.camera)
                let command = ClassroomCommand.updateDeviceState(uuid: user.rtmUUID, state: newDeviceState)
                let sending = self.stateHandler.send(command: command)
                    .map { [weak self] _ -> String in
                        guard let self else { return "" }
                        if user.rtmUUID != self.userUUID, !user.status.deviceState.mic { // Toast for send device request
                            return localizeStrings("SentInvitation")
                        }
                        return ""
                    }
                    .catch { error in
                        return .just(error.localizedDescription)
                    }
                return sending
            }.asDriver(onErrorJustReturn: "Mic task error")

        return Driver.of(allMuteTask,
                         stopTask,
                         onStageTask,
                         whiteboardTask,
                         cameraTask,
                         micTask,
                         cancelRaiseHandTask,
                         rewardTask).merge()
    }

    /// Return should dismiss
    func transformLogoutTap(_ tap: Observable<TapSource>) -> Observable<Bool> {
        tap
            .flatMap { [unowned self] source -> Observable<AlertModel.ActionModel> in
                if self.isOwner {
                    let teacherStartAlert = AlertModel(title: localizeStrings("Close options"),
                                                       message: localizeStrings("Teacher close class room alert detail"),
                                                       preferredStyle: .actionSheet, actionModels: [
                                                           .init(title: localizeStrings("Leaving for now"), style: .default, handler: nil),
                                                           .init(title: localizeStrings("End the class"), style: .destructive, handler: nil),
                                                           .init(title: localizeStrings("Cancel"), style: .cancel, handler: nil),
                                                       ])
                    return self.alertProvider
                        .showActionSheet(with: teacherStartAlert, source: source)
                        .asObservable()
                } else {
                    let studentAlert = AlertModel(title: localizeStrings("Class exit confirming title"),
                                                  message: localizeStrings("Class exit confirming detail"),
                                                  preferredStyle: .actionSheet,
                                                  actionModels: [
                                                      .init(title: localizeStrings("Confirm"), style: .default, handler: nil),
                                                      .init(title: localizeStrings("Cancel"), style: .cancel, handler: nil),
                                                  ])
                    return self.alertProvider
                        .showActionSheet(with: studentAlert, source: source)
                        .asObservable()
                }
            }
            .flatMap { [unowned self] model -> Observable<Bool> in
                // destructive only show when teacher can stop classroom
                if model.style == .cancel { return .just(false) }
                if model.style == .destructive {
                    let stopRecordCommand: Single<Void> = self.recordModel == nil ? .just(()) : self.recordModel!.endRecord().asSingle()
                    return stopRecordCommand
                        .flatMap { [weak self] _ in
                            guard let self else { return .error("self not exist") }
                            return self.stateHandler.send(command: .updateRoomStartStatus(.Stopped))
                        }
                        .asObservable()
                        .map { true }
                } else {
                    return .just(true)
                }
            }
    }

    var recordModel: RecordModel?
    struct RecordingOutput {
        let recording: Observable<Bool>
        let loading: Observable<Bool>
        let layoutUpdate: Observable<Void>
    }

    func transformRecordTap(_ tap: ControlEvent<Void>) -> RecordingOutput {
        let loading = BehaviorRelay<Bool>.init(value: true)

        func startAlert() -> Observable<Bool> {
            alertProvider
                .showAlert(with: .init(message: localizeStrings("TurnOnRecordAlertTip"), preferredStyle: .alert, actionModels: [
                    .cancel,
                    .confirm,
                ]))
                .asObservable()
                .map { $0.style == .default }
                .filter { $0 }
        }

        func finishAlert() -> Observable<Bool> {
            alertProvider
                .showAlert(with: .init(message: localizeStrings("TurnOffReocrdAlertTip"), preferredStyle: .alert, actionModels: [
                    .cancel,
                    .confirm,
                ]))
                .asObservable()
                .map { $0.style == .default }
                .filter { $0 }
        }

        let userOperation = tap
            .asObservable()
            .flatMap { [unowned self] _ -> Observable<Bool> in
                Observable<Bool>.just(self.recordModel != nil)
            }
            .flatMap { recording -> Observable<Bool> in
                let alert = recording ? finishAlert() : startAlert()
                return alert.map { _ in recording }
            }
            .withLatestFrom(onStageUsers, resultSelector: { recording, users in
                (recording, users)
            })
            .flatMap { [unowned self] recording, users -> Observable<Bool> in
                loading.accept(true)
                if recording {
                    return self.recordModel!.endRecord()
                        .do(onNext: { [weak self] _ in
                            loading.accept(false)
                            self?.recordModel = nil
                        })
                        .map { _ in false }
                } else {
                    return RecordModel.create(fromRoomUUID: roomUUID, users: users)
                        .do(onNext: { [weak self] model in
                            loading.accept(false)
                            self?.recordModel = model
                        }).map { _ in true }
                }
            }

        let recording = RecordModel
            .fetchSavedRecordModel().do(onSuccess: { [weak self] model in
                self?.recordModel = model
                loading.accept(false)
            })
            .map { $0 != nil }
            .asObservable()
            .concat(userOperation)

        let layoutUpdate = onStageUsers
            .distinctUntilChanged()
            .filter { [weak self] _ in
                self?.recordModel != nil
            }
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] users -> Observable<Void> in
                self.recordModel!.updateLayout(users: users)
            }

        return .init(recording: recording, loading: loading.asObservable(), layoutUpdate: layoutUpdate)
    }

    func destroy(sender: Any) {
        // Manual deinit it to remove update timer. In case of memory leak
        recordModel = nil
        stateHandler.destroy()
        let startStatus = stateHandler.roomStartStatus.value
        NotificationCenter.default.post(name: classRoomLeavingNotificationName,
                                        object: nil,
                                        userInfo: ["roomUUID": roomUUID,
                                                   "startStatus": startStatus,
                                                   "sender": sender])
    }
}
