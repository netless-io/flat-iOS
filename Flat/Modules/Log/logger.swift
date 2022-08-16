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
        return MultiplexLogHandler(SBLogHandler(filename: "flat-swiftybeaver"), AlibabaLogHandler())
    }
    logger = Logger(label: "")
    logger.logLevel = .trace
}
