//
//  ClassType.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct ClassRoomType: RawRepresentable, Codable, Equatable {
    enum InteractionStrategy {
        case enable
        case disable
        case depending
    }
    
    enum RtcStrategy {
        case teacherOrSpeaking
        case all
        
        func displayingUsers(with users: [RoomUser], ownnerRtmUUID: String) -> [RoomUser] {
            switch self {
            case .all: return users
            case .teacherOrSpeaking:
                return users.filter { $0.status.isSpeak || $0.rtmUUID == ownnerRtmUUID}
            }
        }
    }
    
    var interactionStrategy: InteractionStrategy {
        switch self {
        case .bigClass: return .disable
        case .oneToOne: return .enable
        default:
            return .depending
        }
    }
    
    var rtcStrategy: RtcStrategy {
        if self == .bigClass {
            return .teacherOrSpeaking
        }
        return .all
    }
     
    static let bigClass = ClassRoomType(rawValue: "BigClass")
    static let smallClass = ClassRoomType(rawValue: "SmallClass")
    static let oneToOne = ClassRoomType(rawValue: "OneToOne")
    
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
