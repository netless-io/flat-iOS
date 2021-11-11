//
//  ClassRoomMode.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct ClassRoomMode: RawRepresentable, Codable, Equatable {
    static let lecture = ClassRoomMode(rawValue: "Lecture")
    static let interaction = ClassRoomMode(rawValue: "Interaction")
    
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
