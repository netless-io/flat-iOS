//
//  ClassroomStateMock.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

class RtmMock: RtmProvider {
    var error: RxRelay.PublishRelay<RtmError> = .init()
    var p2pMessage: RxRelay.PublishRelay<(data: Data, sender: String)> = .init()
    func sendP2PMessageFromArray(_ array: [(data: Data, uuid: String)]) -> RxSwift.Single<Void> {
        .just(())
    }
    func sendP2PMessage(data: Data, toUUID UUID: String) -> RxSwift.Single<Void> {
        .just(())
    }
    func login() -> RxSwift.Single<Void> {
        .just(())
    }
    func logout() -> RxSwift.Single<Void> {
        .just(())
    }
}

class ClassroomStateMock: ClassroomStateHandler {
    init() {}
    
    var notifyDeviceOffPublisher: RxRelay.PublishRelay<RequestDeviceType> = .init()
    var requestDevicePublisher: RxRelay.PublishRelay<RequestDeviceType> = .init()
    var requestDeviceResponsePublisher: RxRelay.PublishRelay<DeviceRequestResponse> = .init()
    var banMessagePublisher: RxRelay.PublishRelay<Bool> = .init()
    var rewardPublisher: RxRelay.PublishRelay<String> = .init()
    var chatNoticePublisher: RxRelay.PublishRelay<String> = .init()
    var toastNoticePublisher: RxRelay.PublishRelay<String> = .init()
    var banState: RxRelay.BehaviorRelay<Bool> = .init(value: false)
    var roomStartStatus: RxRelay.BehaviorRelay<RoomStartStatus> = .init(value: .Started)
    var currentOnStageUsers: [String : RoomUser] = [:]
    func checkIfSpeakUserOverMaxCount() -> RxSwift.Single<Bool> {
        return .just(false)
    }
    
    func send(command: ClassroomCommand) -> RxSwift.Single<Void> {
        return .just(())
    }
    
    var users: [RoomUser] = []
    var c = 0
    lazy var m: Observable<[RoomUser]> = {
        Observable<Int>
            .interval(.milliseconds(10), scheduler: MainScheduler.instance)
            .map { _ -> Int in
                self.c += 1
                return self.c
            }
            .filter { $0 <= 3000 }
            .map { id -> [RoomUser] in
                let id = self.c
                var user = RoomUser(rtmUUID: id.description, rtcUID: UInt(id), name: id.description, avatarURL: nil)
                if id > 5 {
                    user.status = .init(isSpeak: false, isRaisingHand: false, camera: false, mic: false, whiteboard: false)
                } else {
                    user.status = .init(isSpeak: true, isRaisingHand: false, camera: false, mic: false, whiteboard: true)
                }
                self.users.append(user)

                print("--::: id ::: \(id)")
//                if id == 500 {
//                    self.users.remove(at: 1)
//                }
                return self.users
            }
            .do { [weak self] users in
                let pairs = users.map { ($0.rtmUUID, $0)}
                self?.currentOnStageUsers = .init(uniqueKeysWithValues: pairs)
            }
    }()
    
    func members() -> RxSwift.Observable<[RoomUser]> {
        m
    }
    
    func memberNameQueryProvider() -> UserInfoQueryProvider {
        return { users in
            let pairs = users.map {
                ($0, UserBriefInfo(name: "user-\($0)", avatar: nil) )
            }
            return .just(.init(uniqueKeysWithValues: pairs))
        }
    }
    
    func setup() -> RxSwift.Single<Void> {
        .just(())
    }
    
    func destroy() {
    }
    
    var error: RxRelay.PublishRelay<ClassroomStateError> = .init()
}
