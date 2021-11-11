//
//  ClassRoom.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/5.
//  Copyright © 2021 agora.io. All rights reserved.
//


import RxSwift
import DifferenceKit
import RxRelay

/// Manage the users and theirs status
class ClassRoom {
    var userStatus: RoomUserStatus {
        users.value.first(where: { $0.rtmUUID == userUUID })!.status
    }
    let userUUID: String
    let isTeacher: Bool
    let userName: String
    let roomType: ClassRoomType
    let messageBan: BehaviorRelay<Bool>
    let status: BehaviorRelay<RoomStartStatus>
    let mode: BehaviorRelay<ClassRoomMode>
    let users: BehaviorRelay<[RoomUser]>
    let roomOwnerRtmUUID: String
    let roomUUID: String
    
    init(userName: String,
         userUUID: String,
         roomType: ClassRoomType,
         messageBan: Bool,
         status: RoomStartStatus,
         mode: ClassRoomMode,
         users: [RoomUser],
         roomOwnerRtmUUID: String,
         roomUUID: String) {
        self.userName = userName
        self.userUUID = userUUID
        self.isTeacher = roomOwnerRtmUUID == userUUID
        self.roomType = roomType
        self.messageBan = .init(value: messageBan)
        self.status = .init(value: status)
        self.mode = .init(value: mode)
        self.users = .init(value: users)
        self.roomOwnerRtmUUID = roomOwnerRtmUUID
        self.roomUUID = roomUUID
    }
    
    func applyWithNoUser() {
        messageBan.accept(false)
        mode.accept(.interaction)
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
    
    func userStatusFor(userUUID: String) -> RoomUserStatus? {
        users.value.first(where: { $0.rtmUUID == userUUID })?.status
    }
    
    func updateUserStatus(_ status: RoomUserStatus) {
        var new = users.value
        let index = new.firstIndex(where: { $0.rtmUUID == userUUID })!
        new[index].status = status
        users.accept(new)
    }
    
    func updateUserStatusFor(userRtmUID: String, status: RoomUserStatus) {
        if userRtmUID == self.userUUID {
            updateUserStatus(status)
            return
        }
        var new = users.value
        if let index = new.firstIndex(where: { $0.rtmUUID == userRtmUID }) {
            new[index].status = status
            users.accept(new)
        }
    }
}
