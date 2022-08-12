//
//  ClassRoomCommandHandler.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import RxSwift
import RxRelay
import Fastboard

enum ClassroomStateError {
    case rtmRemoteLogin
    case whiteboardError(FastRoomError)
    
    var uiAlertString: String {
        switch self {
        case .rtmRemoteLogin:
            return localizeStrings("Rtm abort tips")
        case .whiteboardError(let error):
            return localizeStrings(error.localizedDescription)
        }
    }
}

enum ClassroomCommand {
    case disconnectUser(String)
    case acceptRaiseHand(String)
    case updateDeviceState(uuid: String, state: DeviceState)
    case updateRaiseHand(Bool)
    case ban(Bool)
    case stopInteraction
    case updateRoomStartStatus(RoomStartStatus)
}

protocol ClassroomStateHandler {
    var banMessagePublisher: PublishRelay<Bool> { get }
    var noticePublisher: PublishRelay<String> { get }
    var banState: BehaviorRelay<Bool> { get }
    var classroomModeState: BehaviorRelay<ClassroomMode> { get }
    var roomStartStatus: BehaviorRelay<RoomStartStatus> { get }
    var error: PublishRelay<ClassroomStateError> { get }
    
    func setup() -> Single<Void>
    func send(command: ClassroomCommand) -> Single<Void>
    func members() -> Observable<[RoomUser]>
    func memberNameQueryProvider() -> UsernameQueryProvider
    
    func destroy()
}