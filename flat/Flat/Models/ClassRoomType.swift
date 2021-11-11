//
//  ClassType.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct ClassRoomType: RawRepresentable, Codable, Equatable {
    enum RtcStrategy {
        case teacherOnly
        case all
    }
    
    var rtcStrategy: RtcStrategy {
        if self == .bigClass {
            return .teacherOnly
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
