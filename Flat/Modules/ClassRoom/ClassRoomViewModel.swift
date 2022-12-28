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
    var rtcUsers: Observable<[RoomUser]> {
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

    // Show tips when user's whiteboard permission is ready
    func transOnStageUpdate(whiteboardEnable: Observable<Bool>) -> Observable<String> {
        currentUser
            .map(\.status.isSpeak)
            .distinctUntilChanged()
            .skip(1)
            .flatMap { speak -> Observable<(speak: Bool, joined: Bool)> in
                whiteboardEnable.map { (speak, $0) }
            }.filter {
                ($0.speak && $0.joined) || (!$0.speak && !$0.joined)
            }.flatMap { [weak self] speak, _ -> Observable<String> in
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

    enum RtcInputType {
        case camera
        case mic
    }

    func transformLocalRtcClick(_ input: Observable<RtcInputType>) -> Driver<DeviceState> {
        input.withLatestFrom(currentUser, resultSelector: { a, b in (a, b) })
            .flatMap { [weak self] click, user -> Observable<DeviceState> in
                guard let self else { return .just(.init(mic: user.status.mic, camera: user.status.camera)) }
                var state: DeviceState
                switch click {
                case .camera:
                    state = .init(mic: user.status.mic, camera: !user.status.camera)
                case .mic:
                    state = .init(mic: !user.status.mic, camera: user.status.camera)
                }
                return self.stateHandler.send(command: .updateDeviceState(uuid: self.userUUID, state: state))
                    .asObservable()
                    .map { state }
            }
            .asDriver(onErrorJustReturn: .init(mic: false, camera: false))
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

    struct UserListInput {
        let allMuteTap: Observable<Void>
        let stopInteractingTap: Observable<Void>
        let tapSomeUserOnStage: Observable<RoomUser>
        let tapSomeUserWhiteboard: Observable<RoomUser>
        let tapSomeUserRaiseHand: Observable<RoomUser>
        let tapSomeUserCamera: Observable<RoomUser>
        let tapSomeUserMic: Observable<RoomUser>
    }

    typealias ActionResult = Result<Void, String>
    func transformUserListInput(_ input: UserListInput) -> Driver<ActionResult> {
        let allMuteTask = input.allMuteTap
            .flatMap { [unowned self] _ -> Single<ActionResult> in
                guard self.isOwner else { return .just(.success(())) }
                return self.stateHandler.send(command: .allMute)
                    .map { _ -> ActionResult in .success(()) }
            }.asDriver(onErrorJustReturn: .success(()))

        let stopTask = input.stopInteractingTap
            .flatMap { [unowned self] _ -> Single<ActionResult> in
                guard self.isOwner else { return .just(.success(())) }
                let stopCommand = self.stateHandler.send(command: .stopInteraction)
                    .map { _ -> ActionResult in .success(()) }
                return stopCommand
            }.asDriver(onErrorJustReturn: .success(()))

        let onStageTask = Observable.merge(input.tapSomeUserRaiseHand, input.tapSomeUserOnStage)
            .flatMap { [unowned self] user -> Single<(RoomUser, Bool)> in
                if user.isUsingWhiteboardWritable {
                    return .just((user, false))
                }
                return self.stateHandler.checkIfWritableUserOverMaxCount()
                    .map { r in (user, r) }
            }
            .flatMap { [unowned self] user, overCount -> Single<ActionResult> in
                if overCount {
                    return .just(.failure(localizeStrings("MaxWritableUsersTips")))
                }
                if user.status.isSpeak {
                    if user.rtmUUID == self.userUUID || self.isOwner {
                        return self.stateHandler.send(command: .disconnectUser(user.rtmUUID))
                            .map { _ -> ActionResult in .success(()) }
                    }
                } else {
                    if self.isOwner {
                        return self.stateHandler.send(command: .pickUserOnStage(user.rtmUUID))
                            .map { _ -> ActionResult in .success(()) }
                    }
                }
                return .just(.success(()))
            }.asDriver(onErrorJustReturn: .success(()))

        let whiteboardTask = input.tapSomeUserWhiteboard
            .flatMap { [unowned self] user -> Single<(RoomUser, Bool)> in
                if user.isUsingWhiteboardWritable {
                    return .just((user, false))
                }
                return self.stateHandler.checkIfWritableUserOverMaxCount()
                    .map { r in (user, r) }
            }
            .flatMap { [unowned self] user, overCount -> Single<ActionResult> in
                if overCount {
                    return .just(.failure(localizeStrings("MaxWritableUsersTips")))
                }
                if user.status.whiteboard {
                    if user.rtmUUID == self.userUUID || self.isOwner {
                        return self.stateHandler.send(command: .updateUserWhiteboardEnable(uuid: user.rtmUUID, enable: false))
                            .map { _ -> ActionResult in .success(()) }
                    }
                } else {
                    if self.isOwner {
                        return self.stateHandler.send(command: .updateUserWhiteboardEnable(uuid: user.rtmUUID, enable: true))
                            .map { _ -> ActionResult in .success(()) }
                    }
                }
                return .just(.success(()))
            }.asDriver(onErrorJustReturn: .success(()))

        let cameraTask = input.tapSomeUserCamera
            .flatMap { [unowned self] user -> Single<ActionResult> in
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just(.success(())) }
                return self.stateHandler
                    .send(command: .updateDeviceState(uuid: user.rtmUUID, state: .init(mic: user.status.mic, camera: !user.status.camera)))
                    .map { _ -> ActionResult in .success(()) }
            }
            .asDriver(onErrorJustReturn: .success(()))

        let micTask = input.tapSomeUserMic
            .flatMap { [unowned self] user -> Single<ActionResult> in
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just(.success(())) }
                return self.stateHandler
                    .send(command: .updateDeviceState(uuid: user.rtmUUID, state: .init(mic: !user.status.mic, camera: user.status.camera)))
                    .map { _ -> ActionResult in .success(()) }
            }
            .asDriver(onErrorJustReturn: .success(()))

        return Driver.of(allMuteTask, stopTask, onStageTask, whiteboardTask, cameraTask, micTask).merge()
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
            .withLatestFrom(rtcUsers, resultSelector: { recording, users in
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

        let layoutUpdate = rtcUsers
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

    func destroy() {
        // Manual deinit it to remove update timer. In case of memory leak
        recordModel = nil
        stateHandler.destroy()
        let startStatus = stateHandler.roomStartStatus.value
        NotificationCenter.default.post(name: classRoomLeavingNotificationName,
                                        object: nil,
                                        userInfo: ["roomUUID": roomUUID, "startStatus": startStatus])
    }
}
