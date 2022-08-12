//
//  ClassRoomMode.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/27.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct ClassroomMode: RawRepresentable, Codable, Equatable {
    static let lecture = ClassroomMode(rawValue: "Lecture")
    static let interaction = ClassroomMode(rawValue: "Interaction")
    
    var interactionEnable: Bool {
        return self == .interaction
    }
    
    var rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
