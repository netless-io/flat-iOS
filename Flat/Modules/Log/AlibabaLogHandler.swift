//
//  AliLog.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/15.
//  Copyright © 2022 agora.io. All rights reserved.
//

import AliyunLogProducer
import Logging

class AlibabaLogHandler: LogHandler {
    enum ClientIdentifier {
        case sessionId(String)
        case uid(String)
    }

    func updateAliSLSLogger(with uid: String) {
        client.destroyLogProducer()
        client = Self.createClientWith(identifier: .uid(uid))
    }

    static func createClientWith(identifier: ClientIdentifier) -> LogProducerClient {
        let env = Env()
        let config = LogProducerConfig(endpoint: env.slsEndpoint,
                                       project: env.slsProject,
                                       logstore: "ios",
                                       accessKeyID: env.slsAk,
                                       accessKeySecret: env.slsSk)
        config?.setTopic(env.name)
        switch identifier {
        case let .sessionId(sessionId):
            config?.addTag("sessionId", value: sessionId)
        case let .uid(uid):
            config?.addTag("uid", value: uid)
        }
        // 1 开启断点续传功能， 0 关闭
        // 每次发送前会把日志保存到本地的binlog文件，只有发送成功才会删除，保证日志上传At Least Once
        config?.setPersistent(1)
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first {
            let path = url.appendingPathComponent("flat-sls-log.dat").path
            // 持久化的文件名，需要保证文件所在的文件夹已创建。
            config?.setPersistentFilePath(path)
        }
        // 是否每次AddLog强制刷新，高可靠性场景建议打开
        config?.setPersistentForceFlush(1)
        // 持久化文件滚动个数，建议设置成10。
        config?.setPersistentMaxFileCount(10)
        // 每个持久化文件的大小，建议设置成1-10M
        config?.setPersistentMaxFileSize(1024 * 1024)
        // 本地最多缓存的日志数，不建议超过1M，通常设置为65536即可
        config?.setPersistentMaxLogCount(65536)
        config?.setGetTimeUnixFunc {
            UInt32(Date().timeIntervalSince1970)
        }
        return LogProducerClient(logProducerConfig: config!)
    }

    var client: LogProducerClient
    let sessionId: String?

    init(identifier: ClientIdentifier) {
        switch identifier {
        case let .sessionId(sid):
            sessionId = sid
            client = Self.createClientWith(identifier: .sessionId(sid))
        case let .uid(uid):
            sessionId = nil
            client = Self.createClientWith(identifier: .uid(uid))
        }
    }

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
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
        let aLog = AliyunLogProducer.Log()
        aLog.setTime(useconds_t(Date().timeIntervalSince1970))
        var dic: [AnyHashable: Any] = [
            "Level": level.rawValue,
            "Module": "[\(source)]",
            "Function": function,
            "File": file,
            "Message": "\(message)",
            "Line": line,
            "context": metadata ?? [:],
        ]

        if let sessionId = sessionId {
            dic["sessionId"] = sessionId
        }

        aLog.putContents(dic)

        switch level {
        case .trace:
            client.add(aLog)
        default:
            client.add(aLog, flush: 1)
        }
    }
}
