//
//  ClassRoomType+AgoraVideoSteamType.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AgoraRtcKit
import Foundation

extension ClassRoomType {
    func thumbnailStreamType(isUserTeacher: Bool) -> AgoraVideoStreamType {
        switch self {
        case .oneToOne: return .high
        default:
            return isUserTeacher ? .high : .low
        }
    }
}
