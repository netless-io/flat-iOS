//
//  UserDevicePreferredStatusStore.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UserDevicePreferredStatusStore {
    enum DeviceType: String {
        case camera
        case mic

        var defaultValue: Bool {
            switch self {
            case .camera: return false
            case .mic: return true
            }
        }
    }

    let userDefaults: UserDefaults

    init(userUUID: String) {
        userDefaults = .init(suiteName: userUUID)!
    }

    func getDevicePreferredStatus(_ type: DeviceType) -> Bool {
        (userDefaults.value(forKey: type.rawValue) as? Bool) ?? type.defaultValue
    }

    func updateDevicePreferredStatus(forType type: DeviceType, value: Bool) {
        userDefaults.setValue(value, forKey: type.rawValue)
    }
}
