//
//  RemoteConfigReader.swift
//  Flat
//
//  Created by xuyunshi on 2024/2/28.
//  Copyright © 2024 agora.io. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

enum RemoteConfigKeys: String, CaseIterable {
    case useRTCWorkaround = "rtc_status_bar_workaround"
}

/// Only type  String  / NSNumber / Bool  yet. (Remind, do not use bool directly. Use NSNumber)
/// Server bool value will result in number value. And server 'true' will result in iOS false.
/// Do not use bool value in server. Do not use bool value in server. Do not use bool value in server. Use number instead !!!
class RemoteConfigReader {
    var useRTCWorkaround: Bool {
        let r: NSNumber? = value(for: .useRTCWorkaround)
        return r?.boolValue ?? false
    }
    
    /// Value will never be nil. Return optional for safety.
    private func value<T>(for key: RemoteConfigKeys) -> T? {
        func typeCast(_ i: Any?) -> T? {
            if let result = i as? RemoteConfigValue {
                if let r = result.stringValue as? T {
                    return r
                }
                if let r = result.numberValue as? T {
                    return r
                }
            }
            if let number = i as? NSNumber {
                if let r = number as? T {
                    return r
                }
            }
            if let r = i as? T {
                return r
            }
            return nil
        }
        let fallbackValue = typeCast(defaultDic[key.rawValue])
        guard didSetupRemoteConfig else {
            globalLogger.info("read remote value before setup. \(key.rawValue): \(fallbackValue.debugDescription)")
            return fallbackValue
        }
        guard let result = remoteConfig?.configValue(forKey: key.rawValue) else {
            globalLogger.info("read remote value fail. \(key.rawValue): \(fallbackValue.debugDescription)")
            return fallbackValue
        }
        let r = typeCast(result)
        globalLogger.info("read remote value success. \(key.rawValue): \(r.debugDescription), source: \(result.source.rawValue)")
        return r
    }

    fileprivate var defaultDic: [String: NSObject] = [:]
    fileprivate var remoteConfig: RemoteConfig?
    fileprivate var didSetupRemoteConfig = false

    init() {
        // Setup default value.
        RemoteConfigKeys.allCases.forEach { key in
            let dicKey = key.rawValue
            let value: NSObject
            switch key {
            case .useRTCWorkaround:
                value = NSNumber(false)
            }
            defaultDic[dicKey] = value
        }
    }
    
    func setupRemoteConfig() {
        guard !didSetupRemoteConfig else { return }
        
        remoteConfig = RemoteConfig.remoteConfig()
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        setting.fetchTimeout = 30
        remoteConfig?.configSettings = setting
        remoteConfig?.setDefaults(defaultDic)
        remoteConfig?.fetchAndActivate(completionHandler: { status, error in
            if let error {
                globalLogger.error("remote config fetch error: \(error.localizedDescription)")
            } else {
                globalLogger.info("remote config fetch result status \(status)")
            }
        })
        
        didSetupRemoteConfig = true
    }
    
    func refresh() {
        remoteConfig?.fetchAndActivate(completionHandler: { status, error in
            if let error {
                globalLogger.error("remote config refresh error: \(error)")
            } else {
                globalLogger.info("remote config refresh result status \(status)")
            }
        })
    }
}
