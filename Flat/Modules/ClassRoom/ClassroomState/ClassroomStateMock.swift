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

class ClassroomStateMock: ClassroomStateHandler {
    init() {}
    
    var notifyDeviceOffPublisher: RxRelay.PublishRelay<RequestDeviceType> = .init()
    var requestDevicePublisher: RxRelay.PublishRelay<RequestDeviceType> = .init()
    var requestDeviceResponsePublisher: RxRelay.PublishRelay<DeviceRequestResponse> = .init()
    var banMessagePublisher: RxRelay.PublishRelay<Bool> = .init()
    var rewardPublisher: RxRelay.PublishRelay<String> = .init()
    var noticePublisher: RxRelay.PublishRelay<String> = .init()
    var banState: RxRelay.BehaviorRelay<Bool> = .init(value: false)
    var roomStartStatus: RxRelay.BehaviorRelay<RoomStartStatus> = .init(value: .Started)
    var currentOnStageUsers: [String : RoomUser] = [:]
    func checkIfSpeakUserOverMaxCount() -> RxSwift.Single<Bool> {
        return .just(false)
    }
    
    func send(command: ClassroomCommand) -> RxSwift.Single<Void> {
        return .just(())
    }
    
    func members() -> RxSwift.Observable<[RoomUser]> {
        let users = (1...100).map {
            RoomUser(rtmUUID: $0.description, rtcUID: $0, name: $0.description, avatarURL: nil)
        }
        return .just([]).delay(.seconds(1), scheduler: MainScheduler.instance)
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
