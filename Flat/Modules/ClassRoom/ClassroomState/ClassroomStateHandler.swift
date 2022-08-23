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
    case rtmReconnectingTimeout
    case rtcConnectLost
    case whiteboardError(FastRoomError)
    
    var uiAlertString: String {
        switch self {
        case .rtcConnectLost:
            return localizeStrings("Rtc connect lost tips")
        case .rtmReconnectingTimeout:
            return localizeStrings("Rtm reconnecting timeout tips")
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
    case pickUserOnStage(String)
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
    var roomStartStatus: BehaviorRelay<RoomStartStatus> { get }
    
    func send(command: ClassroomCommand) -> Single<Void>
    func members() -> Observable<[RoomUser]>
    func memberNameQueryProvider() -> UsernameQueryProvider
    var currentOnStageUsers: [String: RoomUser] { get }

    func setup() -> Single<Void>
    func destroy()
    
    var error: PublishRelay<ClassroomStateError> { get }
}
