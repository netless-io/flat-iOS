//
//  Log.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

enum LogModuleType {
    case rtc
    case rtm
    case whiteboard
    case alloc
    case syncedStore
    case api
    
    var prefix: String {
        "[\(String(describing: self).uppercased())]"
    }
}

enum LogLevel {
    case error
    case warning
    case info
    case verbose
    
    var prefix: String {
        return "(\(String(describing: self)))"
    }
}

func log(module: LogModuleType? = nil, level: LogLevel = .info, log: String) {
    if let module = module {
        print("\(module.prefix) \(level.prefix) \(log)")
    } else {
        print("[FLAT] \(level.prefix) \(log)")
    }
}
