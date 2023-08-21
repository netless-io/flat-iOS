//
//  Env+Whiteboard.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/21.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

extension Env {
    var createWhiteboardRegion: FlatRegion {
        FlatRegion(rawValue: value(for: "CREATE_WHITEBOARD_REGION") as String) ?? .CN_HZ
    }
}
