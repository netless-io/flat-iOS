//
//  ClassRoomViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ClassRoomViewModel {
    fileprivate var stateHandler: ClassroomStateHandler!
    
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
                users.filter { $0.status.isSpeak }
            }
    }
    var currentUser: Observable<RoomUser> {
        members
            .map { [weak self] m in
                guard let self = self else { throw "self not exist" }
                return m.first(where: { $0.rtmUUID == self.userUUID}) ?? .empty
            }
            .distinctUntilChanged()
    }
    
    func transOnStageUpdate(whiteboardEnable: Observable<Bool>) -> Observable<String> {
        currentUser
            .map { $0.status.isSpeak }
            .distinctUntilChanged()
            .skip(1)
            .flatMap { speak -> Observable<(speak: Bool, joined: Bool)> in
                whiteboardEnable.map { (speak, $0) }
            }.filter {
                return ($0.speak && $0.joined) || (!$0.speak && !$0.joined)
            }.flatMap { [weak self] (speak, _) -> Observable<String> in
                guard let self = self else { return .error("self not exist") }
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
            guard let self = self else { return true }
            if self.isOwner { return true }
            if ban { return true }
            return currentUser.status.isSpeak
        }
    }
    
    var whiteboardEnable: Observable<Bool> { currentUser.map { $0.status.isSpeak } }
    
    var isRaisingHand: Observable<Bool> {
        currentUser.map { $0.status.isRaisingHand }
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
                users.contains(where: { $0.status.isRaisingHand })
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
         preferredDeviceState: DeviceState) {
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
        let initRoom =  stateHandler.setup()
            .flatMap { [weak self] _ -> Single<Void> in
                guard let self = self else { return .error("self not exist") }
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
        if roomType == .oneToOne && isOwner {
            autoPickMemberOnStageOnce = shareInitRoom
                .flatMap { [weak self] _ -> Observable<[RoomUser]>  in
                    guard let self = self else { return .error("self not exist") }
                    return self.members
                }
                .skip(while: { $0.count < 2 })
                .take(1)
                .flatMap { [weak self ] members -> Observable<RoomUser?> in
                    guard let self = self else { return .error("self not exist") }
                    let speakers = members.filter { $0.status.isSpeak }
                    if speakers.count >= 2 {
                        return .just(nil)
                    }
                    
                    let nonSpeakers = members.filter({
                        $0.rtmUUID != self.userUUID &&
                        !$0.status.isSpeak
                    })
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
        let chatControllerPresentedFetch: (()->Driver<Bool>)
    }
    func initChatChannel(_ input: ChatInput) -> Single<ChatChannelInitValue> {
        let channel = self.commandChannelRequest
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
                return .init(channel: channel,
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
    func transformLocalRtcClick(_ input: Observable<RtcInputType>) ->  Driver<DeviceState> {
        input.withLatestFrom(currentUser, resultSelector: { a, b in return (a,b) })
            .flatMap { [weak self] click, user -> Observable<DeviceState> in
                guard let self = self else { return .just(.init(mic: user.status.mic, camera: user.status.camera)) }
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
            .withLatestFrom(stateHandler.banState, resultSelector: { _, ban in return !ban })
            .flatMap { [weak self] ban -> Observable<Bool> in
                guard let self = self else { return .error("self not exist") }
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
            return user.status
        }
        .asDriver(onErrorJustReturn: .default)
        .flatMap { [weak self] status -> Driver<Bool> in
            guard let self = self else { return .just(false) }
            if status.isSpeak { return .just(false) }
            return self.stateHandler
                .send(command: .updateRaiseHand(!status.isRaisingHand))
                .asDriver(onErrorJustReturn: ())
                .map { !status.isRaisingHand }
        }
    }
    
    struct UserListInput {
        let stopInteractingTap: Observable<Void>
        let disconnectTap: Observable<RoomUser>
        let tapSomeUserRaiseHand: Observable<RoomUser>
        let tapSomeUserCamera: Observable<RoomUser>
        let tapSomeUserMic: Observable<RoomUser>
    }
    typealias ActionResult = Result<Void, String>
    func transformUserListInput(_ input: UserListInput) -> Driver<ActionResult> {
        let stopTask = input.stopInteractingTap
            .flatMap { [unowned self] _ -> Single<ActionResult> in
                guard self.isOwner else { return .just(.success(())) }
                return self.stateHandler.send(command: .stopInteraction)
                    .map { _ -> ActionResult in .success(()) }
            }.asDriver(onErrorJustReturn: .success(()))
        
        let acceptRaiseHandTask = input.tapSomeUserRaiseHand
            .flatMap { [unowned self] user -> Single<(RoomUser, Bool)> in
                return self.stateHandler.checkIfOnStageUserOverMaxCount()
                    .map { r in (user, r)}
            }
            .flatMap { [unowned self] user, overCount -> Single<ActionResult> in
                guard self.isOwner else { return .just(.success(())) }
                if overCount {
                    return .just(.failure(localizeStrings("AccpetRaiseHandOverOnStageCountTip")))
                }
                return self.stateHandler.send(command: .acceptRaiseHand(user.rtmUUID))
                    .map { _ -> ActionResult in .success(()) }
            }.asDriver(onErrorJustReturn: .success(()))
        
        let disconnectTask = input.disconnectTap
            .flatMap { [unowned self] user in
                self.stateHandler.send(command: .disconnectUser(user.rtmUUID))
                    .map { _ -> ActionResult in .success(()) }
            }.asDriver(onErrorJustReturn: .success(()))
        
        let cameraTask = input.tapSomeUserCamera
            .flatMap { [unowned self] user -> Single<ActionResult> in
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just(.success(()))}
                return self.stateHandler
                    .send(command: .updateDeviceState(uuid: user.rtmUUID, state: .init(mic: user.status.mic, camera: !user.status.camera)))
                    .map { _ -> ActionResult in .success(()) }
            }
            .asDriver(onErrorJustReturn: .success(()))
        
        let micTask = input.tapSomeUserMic
            .flatMap { [unowned self] user -> Single<ActionResult> in
                guard user.rtmUUID == self.userUUID || self.isOwner else { return .just(.success(()))}
                return self.stateHandler
                    .send(command: .updateDeviceState(uuid: user.rtmUUID, state: .init(mic: !user.status.mic, camera: user.status.camera)))
                    .map { _ -> ActionResult in .success(()) }
            }
            .asDriver(onErrorJustReturn: .success(()))
        
        return Driver.of(stopTask, acceptRaiseHandTask, disconnectTask, cameraTask, micTask).merge()
    }
    
    /// Return should dismiss
    func transformLogoutTap(_ tap: Observable<TapSource>) -> Observable<Bool> {
        tap
            .flatMap { [unowned self] source -> Observable<AlertModel.ActionModel> in
                if self.isOwner {
                    let teacherStartAlert = AlertModel(title: NSLocalizedString("Close options", comment: ""),
                                                       message: NSLocalizedString("Teacher close class room alert detail", comment: ""),
                                                       preferredStyle: .actionSheet, actionModels: [
                                                        .init(title: NSLocalizedString("Leaving for now", comment: ""), style: .default, handler: nil),
                                                        .init(title: NSLocalizedString("End the class", comment: ""), style: .destructive, handler: nil),
                                                        .init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)])
                    return self.alertProvider
                        .showActionSheet(with: teacherStartAlert, source: source)
                        .asObservable()
                    
                } else {
                    let studentAlert = AlertModel(title: NSLocalizedString("Class exit confirming title", comment: ""),
                                                  message: NSLocalizedString("Class exit confirming detail", comment: ""),
                                                  preferredStyle: .actionSheet,
                                                  actionModels: [
                                                    .init(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: nil),
                                                    .init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)]
                    )
                    return self.alertProvider
                        .showActionSheet(with: studentAlert, source: source)
                        .asObservable()
                }
            }
            .flatMap { [unowned self] model -> Observable<Bool> in
                // destructive only show when teacher can stop classroom
                if model.style == .cancel { return .just(false) }
                if model.style == .destructive {
                    return self.stateHandler.send(command: .updateRoomStartStatus(.Stopped))
                        .asObservable().map { true }
                } else {
                    
                    return .just(true)
                }
            }
    }
    
    struct RecordOutput {
        let isRecording: Observable<Bool>
        let recordingDuration: Observable<TimeInterval>
    }
    var recordModel: RecordModel?
    func transformMoreTap(moreTap: ControlEvent<TapSource>, topRecordingTap: ControlEvent<Void>) -> RecordOutput {
        let topManualEnding = topRecordingTap
            .asObservable()
            .flatMap { [unowned self] in
                return self.recordModel!
                    .endRecord()
                    .asObservable()
                    .do(onNext: { [weak self] in
                        self?.recordModel = nil
                    })
            }
        
        let moreToRecording = moreTap
            .flatMap { [unowned self] source -> Single<(TapSource, Bool)> in
                let isRecording = self.recordModel != nil
                return Single<Bool>.just(isRecording).map { (source, $0) }
            }
            .flatMap { [unowned self] source, r -> Single<(AlertModel.ActionModel, Bool)> in
                let str = NSLocalizedString(r ? "EndRecording" : "StartRecording", comment: "")
                let alert = self.alertProvider.showActionSheet(with: .init(title: nil,
                                                                            message: nil,
                                                                            preferredStyle: .actionSheet,
                                                                            actionModels: [
                                                                                .init(title: str, style: .default, handler: { _ in }),
                                                                                .cancel]),
                                                                source: source)
                return alert.map { model in return (model, r) }
            }
            .filter { $0.0.style != .cancel }
            .flatMap { [unowned self] source, recording -> Observable<(Bool, [RoomUser])> in
                return self.members.map { (recording, $0) }
            }
            .flatMap { [weak self] recording, members -> Observable<Bool> in
                guard let self = self else { throw "self not exist" }
                if recording {
                    return self.recordModel!.endRecord()
                        .do(onNext: { [weak self] in
                            self?.recordModel = nil
                        }).map { false }
                } else {
                    return RecordModel
                        .create(fromRoomUUID: self.roomUUID, joinedUsers: members)
                        .do(onNext: { [weak self] model in
                            self?.recordModel = model
                        }).map { _ in return true }
                }
            }
        
        let recording = Observable.merge(moreToRecording, topManualEnding.map { false } )
            .share(replay: 1, scope: .whileConnected)
        
        let recordingDuration: Observable<TimeInterval> = recording
            .flatMapLatest { r -> Observable<Int> in
                if r {
                    return Observable<Int>.interval(.milliseconds(1000),
                                             scheduler: ConcurrentDispatchQueueScheduler(queue: .global()))
                } else {
                    return .just(0)
                }
            }
            .map { [weak self] _ -> TimeInterval in
                if let date = self?.recordModel?.startDate {
                    return Date().timeIntervalSince(date)
                } else {
                    return 0
                }
            }
            .do(onNext: { [weak self] i in
                if Int(i) % 10 == 0 {
                    self?.recordModel?.updateServerEndTime()
                }
            })
        return RecordOutput(isRecording: recording, recordingDuration: recordingDuration)
    }
    
    func destroy() {
        stateHandler.destroy()
        let startStatus = stateHandler.roomStartStatus.value
        NotificationCenter.default.post(name: classRoomLeavingNotificationName,
                                        object: nil,
                                        userInfo: ["roomUUID": roomUUID, "startStatus": startStatus])
    }
}
