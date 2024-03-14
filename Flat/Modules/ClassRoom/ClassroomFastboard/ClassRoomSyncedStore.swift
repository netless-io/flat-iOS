//
//  FastboardSyncedStore.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/27.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import Whiteboard

protocol FlatSyncedStoreCommandDelegate: AnyObject {
    func flatSyncedStoreDidReceiveCommand(_ store: ClassRoomSyncedStore, command: ClassRoomSyncedStore.Command)
}

private let newValueKey = "newValue"
private let deviceStateName = "deviceState"
private let classroomStateName = "classroom"
private let whiteboardStateName = "whiteboard"
private let onStageUsersName = "onStageUsers"

private let classroomDefaultValue: [AnyHashable: Any] = [
    ClassRoomSyncedStore.RoomState.Keys.raiseHandUsers.rawValue: [String](),
    ClassRoomSyncedStore.RoomState.Keys.ban.rawValue: false,
]
private let onStageUserDefaultValue: [AnyHashable: Any] = [:]
private let whiteboardDefaultValue: [AnyHashable: Any] = [:]

/// FlatSyncedStore get value from whiteboard. Init the state with `setup(with:)` function
/// Using `getValues(completionHandler:)` to get syncedStore value
/// Setting `delegate` to get command notification
class ClassRoomSyncedStore: NSObject, SyncedStoreUpdateCallBackDelegate {
    typealias SyncedStoreSuccessValue = (deviceState: [String: DeviceState],
                                         roomState: RoomState,
                                         onStageUsers: [String: Bool],
                                         whiteboardUsers: [String: Bool])
    typealias SyncedStoreResult = Result<SyncedStoreSuccessValue, Error>
    typealias SyncedStoreValuesCallback = (SyncedStoreResult) -> Void

    struct UserDeviceState: Encodable {
        let uid: String
        let state: DeviceState
    }

    struct RoomState {
        enum Keys: String {
            case raiseHandUsers
            case ban
        }

        let raiseHandUsers: [String]
        let ban: Bool
    }

    enum Command {
        case raiseHandUsersUpdate([String])
        case onStageUsersUpdate([String: Bool])
        case whiteboardUsersUpdate([String: Bool])
        case banUpdate(Bool)

        case deviceStateUpdate([String: DeviceState])
    }

    fileprivate var isConnected = false
    fileprivate var syncStore: SyncedStore!
    fileprivate var waitingCallbacks: [SyncedStoreValuesCallback] = []
    weak var delegate: FlatSyncedStoreCommandDelegate?

    func setup(with displayer: WhiteDisplayer) {
        globalLogger.info("setup room")
        isConnected = false
        syncStore = displayer.obtainSyncedStore()
        let group = DispatchGroup()
        var error: Error?

        globalLogger.trace("connect \(deviceStateName)")
        group.enter()
        syncStore.connectStorage(deviceStateName, defaultValue: [:]) { _, err in
            if let err { error = err }
            globalLogger.trace("connect \(deviceStateName) success")
            group.leave()
        }

        globalLogger.trace("connect \(classroomStateName), default \(classroomDefaultValue)")
        group.enter()
        syncStore.connectStorage(classroomStateName, defaultValue: classroomDefaultValue) { _, err in
            if let err { error = err }
            globalLogger.trace("connect \(classroomStateName) success")
            group.leave()
        }

        globalLogger.trace("connect \(onStageUsersName), default \(onStageUserDefaultValue)")
        group.enter()
        syncStore.connectStorage(onStageUsersName, defaultValue: onStageUserDefaultValue) { _, err in
            if let err { error = err }
            globalLogger.trace("connect \(onStageUsersName) success")
            group.leave()
        }
        
        globalLogger.trace("connect \(whiteboardStateName), default \(whiteboardDefaultValue)")
        group.enter()
        syncStore.connectStorage(whiteboardStateName, defaultValue: whiteboardDefaultValue) { _, err in
            if let err { error = err }
            globalLogger.trace("connect \(whiteboardStateName) success")
            group.leave()
        }

        group.notify(queue: .main) {
            if let error {
                globalLogger.error("connect fail \(error)")
                self._fireCallbacksWith(error)
            } else {
                globalLogger.info("connect success, start getValues")
                self.isConnected = true
                self._getValues()
            }
        }
    }

    func destroy() {
        if isConnected {
            syncStore.disconnectStorage(deviceStateName)
            syncStore.disconnectStorage(classroomStateName)
        }
    }

    func sendCommand(_ command: Command) throws {
        func dicFromEncodable(_ encodable: some Encodable) throws -> Any {
            let data = try JSONEncoder().encode(encodable)
            return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        }
        globalLogger.info("try send command \(command)")
        switch command {
        case let .raiseHandUsersUpdate(raiseHandUsers):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.raiseHandUsers.rawValue: dicFromEncodable(raiseHandUsers)])
        case let .onStageUsersUpdate(stageUsers):
            try syncStore.setStorageState(onStageUsersName, partialState: dicFromEncodable(stageUsers) as! [AnyHashable: Any])
        case let .whiteboardUsersUpdate(whiteboardUsers):
            try syncStore.setStorageState(whiteboardStateName, partialState: dicFromEncodable(whiteboardUsers) as! [AnyHashable: Any])
        case let .banUpdate(ban):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.ban.rawValue: dicFromEncodable(ban)])
        case let .deviceStateUpdate(dic):
            try syncStore.setStorageState(deviceStateName, partialState: dicFromEncodable(dic) as! [AnyHashable: Any])
        }
    }

    func getValues() -> Single<SyncedStoreSuccessValue> {
        .create { [weak self] ob in
            guard let self else {
                ob(.failure("self not exist"))
                return Disposables.create()
            }
            self.getValues { r in
                switch r {
                case let .success(response):
                    ob(.success(response))
                case let .failure(error):
                    ob(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    /// Get syncedStore value synchrony
    func getValues(completionHandler: @escaping SyncedStoreValuesCallback) {
        waitingCallbacks.append(completionHandler)
        if isConnected {
            _getValues()
        }
    }

    fileprivate func _fireCallbacksWith(_ error: Error) {
        waitingCallbacks.forEach { $0(.failure(error)) }
        waitingCallbacks = []
    }

    fileprivate func _fireCallbacksWith(_ value: SyncedStoreSuccessValue) {
        waitingCallbacks.forEach { $0(.success(value)) }
        waitingCallbacks = []
    }

    fileprivate func _getValues() {
        var getValuesError: Error?
        var deviceState: [String: DeviceState] = [:]
        var roomState: RoomState!
        var onStageUsers: [String: Bool]!
        var whiteboardUsers: [String: Bool]!
        let decoder = JSONDecoder()

        let group = DispatchGroup()

        globalLogger.trace("start get \(deviceStateName)")
        group.enter()
        syncStore.getStorageState(deviceStateName) { values in
            if let values {
                for value in values {
                    if let uid = value.key as? String {
                        if let data = (value.value as? NSDictionary)?._white_yy_modelToJSONData() {
                            do {
                                let state = try decoder.decode(DeviceState.self, from: data)
                                deviceState[uid] = state
                                globalLogger.trace("start \(deviceStateName) success \(state)")
                            } catch {
                                getValuesError = error
                                globalLogger.error("get \(deviceStateName) error \(error)")
                            }
                        }
                    }
                }
            } else {
                getValuesError = "get device state error"
                globalLogger.error("get \(deviceStateName) error empty value")
            }
            group.leave()
        }

        globalLogger.info("start get \(onStageUsersName)")
        group.enter()
        syncStore.getStorageState(onStageUsersName) { value in
            if let us = value as? [String: Bool] {
                onStageUsers = us
                globalLogger.trace("start \(onStageUsersName) success \(us)")
            } else {
                getValuesError = "get on stage users error: \(value?.description ?? "")"
                globalLogger.error("get \(onStageUsersName) error \(String(describing: getValuesError))")
            }
            group.leave()
        }

        globalLogger.info("start get \(classroomStateName)")
        group.enter()
        syncStore.getStorageState(classroomStateName) { values in
            if let values {
                let raiseHandUsers = values[RoomState.Keys.raiseHandUsers.rawValue] as? [String] ?? []
                let ban = values[RoomState.Keys.ban.rawValue] as? Bool ?? false
                roomState = RoomState(raiseHandUsers: raiseHandUsers, ban: ban)
                globalLogger.trace("start \(classroomStateName) success \(String(describing: roomState))")
            } else {
                getValuesError = "get room state error"
                globalLogger.error("get \(classroomStateName) error \(String(describing: getValuesError))")
            }
            group.leave()
        }
        
        globalLogger.info("start get \(whiteboardStateName)")
        group.enter()
        syncStore.getStorageState(whiteboardStateName) { value in
            if let us = value as? [String: Bool] {
                whiteboardUsers = us
                globalLogger.trace("start \(whiteboardStateName) success \(us)")
            } else {
                getValuesError = "get on stage users error: \(value?.description ?? "")"
                globalLogger.error("get \(whiteboardStateName) error \(String(describing: getValuesError))")
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if let error = getValuesError {
                self._fireCallbacksWith(error)
                globalLogger.error("_getValues error \(error)")
            } else {
                self._fireCallbacksWith((deviceState, roomState, onStageUsers, whiteboardUsers))
                globalLogger.trace("_getValues success")
            }
        }
    }

    func syncedStoreDidUpdateStoreName(_ name: String, partialValue: [AnyHashable: Any]) {
        globalLogger.trace("receive partial update \(name), \(partialValue)")
        if name == deviceStateName {
            syncStore.getStorageState(name) { [weak self] value in
                guard let self else { return }
                let res = (value as? [String: Any])?.compactMapValues { object -> DeviceState? in
                    if let object = object as? NSDictionary {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)
                            let state = try JSONDecoder().decode(DeviceState.self, from: data)
                            return state
                        } catch {
                            globalLogger.error("device state synced store update error: \(error)")
                        }
                    }
                    return nil
                }
                if let res {
                    self.delegate?.flatSyncedStoreDidReceiveCommand(self, command: .deviceStateUpdate(res))
                }
            }
        }

        if name == whiteboardStateName {
            syncStore.getStorageState(name) { [weak self] value in
                guard let self else { return }
                if let us = value as? [String: Bool] {
                    self.delegate?.flatSyncedStoreDidReceiveCommand(self, command: .whiteboardUsersUpdate(us))
                } else {
                    globalLogger.error("get whiteboard users error: \(value?.description ?? "")")
                }
            }
        }
        
        if name == onStageUsersName {
            syncStore.getStorageState(name) { [weak self] value in
                guard let self else { return }
                if let us = value as? [String: Bool] {
                    self.delegate?.flatSyncedStoreDidReceiveCommand(self, command: .onStageUsersUpdate(us))
                } else {
                    globalLogger.error("get on stage users error: \(value?.description ?? "")")
                }
            }
        }

        if name == classroomStateName {
            for partial in partialValue {
                if let key = partial.key as? String,
                   let roomStateKey = RoomState.Keys(rawValue: key)
                {
                    switch roomStateKey {
                    case .raiseHandUsers:
                        if let dic = partial.value as? NSDictionary,
                           let raiseHandUserIds = dic[newValueKey] as? [String]
                        {
                            delegate?.flatSyncedStoreDidReceiveCommand(self, command: .raiseHandUsersUpdate(raiseHandUserIds))
                        }
                    case .ban:
                        if let dic = partial.value as? NSDictionary,
                           let isBan = dic[newValueKey] as? Bool
                        {
                            delegate?.flatSyncedStoreDidReceiveCommand(self, command: .banUpdate(isBan))
                        }
                    }
                }
            }
        }
    }
}
