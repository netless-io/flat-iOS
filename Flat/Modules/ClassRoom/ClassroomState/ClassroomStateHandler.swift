//
//  ClassRoomCommandHandler.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import RxRelay
import RxSwift

enum RequestDeviceType {
    case camera
    case mic
}

struct DeviceRequestResponse {
    let type: RequestDeviceType
    let userUUID: String
    let userName: String
    let isOn: Bool
    
    var toast: String {
        if !isOn {
            switch type {
            case .camera:
                return userName + " " + localizeStrings("CameraRequestReject")
            case .mic:
                return userName + " " + localizeStrings("MicRequestReject")
            }
        }
        return ""
    }
}

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
        case let .whiteboardError(error):
            return localizeStrings(error.localizedDescription)
        }
    }
}

enum ClassroomCommand {
    case disconnectUser(String)
    case pickUserOnStage(String)
    case updateUserWhiteboardEnable(uuid: String, enable: Bool)
    case updateDeviceState(uuid: String, state: DeviceState)
    case updateRaiseHand(Bool)
    case ban(Bool)
    case stopInteraction
    case allMute
    case updateRoomStartStatus(RoomStartStatus)
    case requestDeviceResponse(type: RequestDeviceType, on: Bool)
}

protocol ClassroomStateHandler {
    var notifyDeviceOffPublisher: PublishRelay<RequestDeviceType> { get }
    var requestDevicePublisher: PublishRelay<RequestDeviceType> { get }
    var requestDeviceResponsePublisher: PublishRelay<DeviceRequestResponse> { get }
    var banMessagePublisher: PublishRelay<Bool> { get }
    var noticePublisher: PublishRelay<String> { get }
    var banState: BehaviorRelay<Bool> { get }
    var roomStartStatus: BehaviorRelay<RoomStartStatus> { get }
    var currentOnStageUsers: [String: RoomUser] { get }

    func checkIfWritableUserOverMaxCount() -> Single<Bool>
    func send(command: ClassroomCommand) -> Single<Void>
    func members() -> Observable<[RoomUser]>
    func memberNameQueryProvider() -> UserInfoQueryProvider

    func setup() -> Single<Void>
    func destroy()

    var error: PublishRelay<ClassroomStateError> { get }
}
