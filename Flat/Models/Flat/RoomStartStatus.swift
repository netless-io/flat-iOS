//
//  RoomStartStatus.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct RoomStartStatus: RawRepresentable, Codable, Equatable {
    static let Idle = RoomStartStatus(rawValue: "Idle")
    static let Started = RoomStartStatus(rawValue: "Started")
    static let Stopped = RoomStartStatus(rawValue: "Stopped")
    static let Paused = RoomStartStatus(rawValue: "Paused")

    let rawValue: String

    func getDisplayStatus() -> Self {
        self == .Paused ? RoomStartStatus.Started : self
    }
}
