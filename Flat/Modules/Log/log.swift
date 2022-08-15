//
//  Log.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

let logQueue = DispatchQueue(label: "log.flat")

enum LogModuleType {
    case rtc
    case rtm
    case whiteboard
    case alloc
    case syncedStore
    case api
    case flat
    
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

let log = Log()

struct Log {
    fileprivate init() {}
    private func msg(_ items: Any...) -> String {
        items.reduce(into: "") { partialResult, i in
            partialResult += " \(i)"
        }
    }
    
    func verbose(module: LogModuleType = .flat, _ items: Any...) {
        logQueue.async {
            log(module: module, level: .verbose, log: msg(items))
        }
    }
    
    func info(module: LogModuleType = .flat, _ items: Any...) {
        logQueue.async {
            log(module: module, level: .info, log: msg(items))
        }
    }
    
    func warning(module: LogModuleType = .flat, _ items: Any...) {
        logQueue.async {
            log(module: module, level: .warning, log: msg(items))
        }
    }
    
    func error(module: LogModuleType = .flat, _ items: Any...) {
        logQueue.async {
            log(module: module, level: .error, log: msg(items))
        }
    }
}

fileprivate func log(module: LogModuleType, level: LogLevel = .info, log: String) {
    print("\(module.prefix) \(level.prefix) \(log)")
}
