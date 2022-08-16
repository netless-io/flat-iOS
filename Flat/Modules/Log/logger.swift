//
//  Log.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Logging

var logger: Logger!

func bootstrapLog() {
    LoggingSystem.bootstrap { label in
        return MultiplexLogHandler([SBLogHandler(), AlibabaLogHandler()])
    }
    logger = Logger(label: "")
    logger.logLevel = .trace

    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    let device = UIDevice.current
    let memoryMB = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
    logger.info("type: \(device.model), systemVersion: \(device.systemVersion), model: \(identifier), memory: \(memoryMB) MB")
}
