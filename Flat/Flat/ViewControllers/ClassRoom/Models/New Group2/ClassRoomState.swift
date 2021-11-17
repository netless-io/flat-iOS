//
//  ClassRoom1.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

struct ClassRoomState {
    let startStatus: BehaviorRelay<RoomStartStatus>
    let messageBan: BehaviorRelay<Bool>
    let mode: BehaviorRelay<ClassRoomMode>
    let users: BehaviorRelay<[RoomUser]>
    
    let roomType: ClassRoomType
    let roomOwnerRtmUUID: String
    let roomUUID: String
    
    init(roomType: ClassRoomType,
         roomOwnerRtmUUID: String,
         roomUUID: String,
         messageBan: Bool,
         status: RoomStartStatus,
         mode: ClassRoomMode,
         users: [RoomUser]) {
        self.startStatus = .init(value: status)
        self.messageBan = .init(value: messageBan)
        self.mode = .init(value: mode)
        self.users = .init(value: users)
        self.roomType = roomType
        self.roomOwnerRtmUUID = roomOwnerRtmUUID
        self.roomUUID = roomUUID
    }
    
    func applyWithNoUser() {
        messageBan.accept(false)
        if startStatus.value == .Started {
            mode.accept(.lecture)
        } else {
            mode.accept(.interaction)
        }
        print("init room with no users")
    }
    
    func appendUser(_ user: RoomUser) {
        var new = users.value
        if let index = new.firstIndex(where: { $0.rtmUUID == user.rtmUUID }) {
            new[index] = user
        } else {
            new.append(user)
        }
        users.accept(new)
    }
    
    func appendUser(fromContentsOf newUsers: [RoomUser]) {
        var new = users.value
        for user in newUsers {
            if let index = new.firstIndex(where: { $0.rtmUUID == user.rtmUUID }) {
                new[index] = user
            } else {
                new.append(user)
            }
        }
        users.accept(new)
    }
    
    func removeUser(forUUID UUID: String) {
        var new = users.value
        new.removeAll(where: { $0.rtmUUID == UUID })
        users.accept(new)
    }
    
    func userStatusFor(userUUID: String) -> RoomUserStatus? {
        users.value.first(where: { $0.rtmUUID == userUUID })?.status
    }
    
    func updateUserStatusFor(userRtmUID: String, status: RoomUserStatus) {
        var new = users.value
        if let index = new.firstIndex(where: { $0.rtmUUID == userRtmUID }) {
            new[index].status = status
            users.accept(new)
        }
    }
}
