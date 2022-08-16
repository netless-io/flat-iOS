//
//  AliLog.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/15.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Logging

struct AlibabaLogHandler: LogHandler {
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }
    
    var metadata: Logger.Metadata = [:]
    
    var logLevel: Logger.Level = .info
    
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        
    }
}
