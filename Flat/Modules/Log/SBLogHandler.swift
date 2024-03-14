//
//  SBLogHandler.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Logging
import SwiftyBeaver

let flatLogFilePrefix = "flat.log"
private let logFileAmount = 3
private func sbLogURL() -> URL? {
    if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
        let url = cacheURL.appendingPathComponent("\(flatLogFilePrefix)")
        return url
    }
    return nil
}

struct SBLogHandler: LogHandler {
    let globalLogger: SwiftyBeaver.Type

    init() {
        globalLogger = SwiftyBeaver.self

        #if DEBUG
            let console = ConsoleDestination()
            console.minLevel = .info
            console.format = "$DHH:mm:ss.SSS$d $C$L$c - $M"
            globalLogger.addDestination(console)
        #endif

        if let url = sbLogURL() {
            let exist = FileManager.default.fileExists(atPath: url.path)
            if !exist {
                let initData = "Date,Level,Function,FILE,MODULE,Message\n".data(using: .utf8)
                FileManager.default.createFile(atPath: url.path, contents: initData)
            }

            #if DEBUG
                print("log file", url)
            #endif

            let file = FileDestination(logFileURL: url)
            file.logFileAmount = logFileAmount
            file.colored = false
            file.minLevel = .verbose

            file.format = "$DHH:mm:ss.SSS$d,$C$L$c,$F:$l,$N,$M\n"
            globalLogger.addDestination(file)
        }
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }

    var metadata: Logger.Metadata = [:]

    var logLevel: Logger.Level = .trace

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt)
    {
        let msg = "\(message)".replacingOccurrences(of: ", ", with: " ").replacingOccurrences(of: "\n", with: "")
        let formattedMsg = SensetiveLogFilter.filter("\(source.isEmpty ? "" : "[\(source)],") \(msg)")
        switch level {
        case .trace:
            globalLogger.verbose(formattedMsg, file, function, line: Int(line), context: metadata)
        case .debug:
            globalLogger.info(formattedMsg, file, function, line: Int(line), context: metadata)
        case .info:
            globalLogger.info(formattedMsg, file, function, line: Int(line), context: metadata)
        case .notice:
            globalLogger.warning(formattedMsg, file, function, line: Int(line), context: metadata)
        case .warning:
            globalLogger.warning(formattedMsg, file, function, line: Int(line), context: metadata)
        case .error:
            globalLogger.error(formattedMsg, file, function, line: Int(line), context: metadata)
        case .critical:
            globalLogger.error(formattedMsg, file, function, line: Int(line), context: metadata)
        }
    }
}
