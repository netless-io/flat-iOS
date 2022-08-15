//
//  FastboardSyncedStore.swift
//  Flat
//
//  Created by xuyunshi on 2022/7/27.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Whiteboard
import RxSwift

protocol FlatSyncedStoreCommandDelegate: AnyObject {
    func flatSyncedStoreDidReceiveCommand(_ store: ClassRoomSyncedStore, command: ClassRoomSyncedStore.Command)
}

private let newValueKey = "newValue"
private let deviceStateName = "deviceState"
private let classroomStateName = "classroom"
private let classroomDefaultValue: [AnyHashable: Any] = [
    ClassRoomSyncedStore.RoomState.Keys.classMode.rawValue: ClassroomMode.lecture.rawValue,
    ClassRoomSyncedStore.RoomState.Keys.raiseHandUsers.rawValue: [],
    ClassRoomSyncedStore.RoomState.Keys.ban.rawValue: false,
    ClassRoomSyncedStore.RoomState.Keys.onStageUsers.rawValue: [:]
]

/// FlatSyncedStore get value from whiteboard. Init the state with `setup(with:)` function
/// Using `getValues(completionHandler:)` to get syncedStore value
/// Setting `delegate` to get command notification
class ClassRoomSyncedStore: NSObject, SyncedStoreUpdateCallBackDelegate {
    typealias SyncedStoreSuccessValue = (deviceState: [String: DeviceState], roomState: RoomState)
    typealias SyncedStoreResult = Result<SyncedStoreSuccessValue, Error>
    typealias SyncedStoreValuesCallback = (SyncedStoreResult)->Void
    
    struct UserDeviceState: Encodable {
        let uid: String
        let state: DeviceState
    }
    struct RoomState {
        enum Keys: String {
            case classMode
            case raiseHandUsers
            case ban
            case onStageUsers
        }
        
        let classMode: ClassroomMode
        let raiseHandUsers: [String]
        let ban: Bool
        let onStageUsers: [String: Bool]
    }
    enum Command {
        case classroomModeUpdate(ClassroomMode)
        case raiseHandUsersUpdate([String])
        case onStageUsersUpdate([String: Bool])
        case banUpdate(Bool)
        
        case deviceStateUpdate([String: DeviceState])
    }
    
    fileprivate var isConnected = false
    fileprivate var syncStore: SyncedStore!
    fileprivate var waitingCallbacks: [SyncedStoreValuesCallback] = []
    weak var delegate: FlatSyncedStoreCommandDelegate?
    
    func setup(with room: WhiteRoom) {
        isConnected = false
        syncStore = room.obtainSyncedStore()
        syncStore.delegate = self
        let group = DispatchGroup()
        group.enter()
        var error: Error?
        syncStore.connectStorage(deviceStateName, defaultValue: [:]) { initState, err in
            if let err = err { error = err }
            group.leave()
        }
        group.enter()
        syncStore.connectStorage(classroomStateName, defaultValue: classroomDefaultValue) { initState, err in
            if let err = err { error = err }
            group.leave()
        }
        group.notify(queue: .main) {
            if let error = error {
                self._fireCallbacksWith(error)
            } else {
                self.isConnected = true
                self._getValues()
            }
        }
    }
    
    func destroy() {
        syncStore.disconnectStorage(deviceStateName)
        syncStore.disconnectStorage(classroomStateName)
    }
    
    func sendCommand(_ command: Command) throws {
        func dicFromEncodable<T: Encodable>(_ encodable: T) throws -> Any {
            let data = try JSONEncoder().encode(encodable)
            return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        }
        Log.info(module: .syncedStore, "syncedStore try send command \(command)")
        switch command {
        case .classroomModeUpdate(let classroomMode):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.classMode.rawValue: dicFromEncodable(classroomMode)])
        case .raiseHandUsersUpdate(let raiseHandUsers):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.raiseHandUsers.rawValue: dicFromEncodable(raiseHandUsers)])
        case .onStageUsersUpdate(let stageUsers):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.onStageUsers.rawValue: dicFromEncodable(stageUsers)])
        case .banUpdate(let ban):
            try syncStore.setStorageState(classroomStateName, partialState: [RoomState.Keys.ban.rawValue: dicFromEncodable(ban)])
        case .deviceStateUpdate(let dic):
            try syncStore.setStorageState(deviceStateName, partialState: dicFromEncodable(dic) as! [AnyHashable: Any])
        }
    }
    
    func getValues() -> Single<SyncedStoreSuccessValue> {
        .create { [weak self] ob in
            guard let self = self else {
                ob(.failure("self not exist"))
                return Disposables.create()
            }
            self.getValues { r in
                switch r {
                case .success(let response):
                    ob(.success(response))
                case .failure(let error):
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
        waitingCallbacks.forEach { $0(.failure(error))}
        waitingCallbacks = []
    }
    
    fileprivate func _fireCallbacksWith(_ value: SyncedStoreSuccessValue) {
        waitingCallbacks.forEach { $0(.success(value))}
        waitingCallbacks = []
    }
    
    fileprivate func _getValues() {
        var getValuesError: Error?
        var deviceState: [String: DeviceState] = [:]
        var roomState: RoomState!
        let group = DispatchGroup()
        group.enter()
        let decoder = JSONDecoder()
        syncStore.getStorageState(deviceStateName) { values in
            if let values = values {
                for value in values {
                    if let uid = value.key as? String {
                        if let data = (value.value as? NSDictionary)?.yy_modelToJSONData() {
                            do {
                                let state = try decoder.decode(DeviceState.self, from: data)
                                deviceState[uid] = state
                            }
                            catch {
                                getValuesError = error
                            }
                        }
                    }
                }
            } else {
                getValuesError = "get device state error"
            }
            group.leave()
        }
        group.enter()
        syncStore.getStorageState(classroomStateName) { values in
            if let values = values {
                let mode = ClassroomMode(rawValue: values[RoomState.Keys.classMode.rawValue] as? String ?? "")
                let raiseHandUsers = values[RoomState.Keys.raiseHandUsers.rawValue] as? [String] ?? []
                let ban = values[RoomState.Keys.ban.rawValue] as? Bool ?? false
                let onStageUsers = values[RoomState.Keys.onStageUsers.rawValue] as? [String: Bool] ?? [:]
                roomState = RoomState(classMode: mode, raiseHandUsers: raiseHandUsers, ban: ban, onStageUsers: onStageUsers)
            } else {
                getValuesError = "get room state error"
            }
            group.leave()
        }
        group.notify(queue: .main) {
            if let error = getValuesError {
                self._fireCallbacksWith(error)
            } else {
                self._fireCallbacksWith((deviceState, roomState))
            }
        }
    }
    
    func syncedStoreDidUpdateStoreName(_ name: String, partialValue: [AnyHashable : Any]) {
        Log.verbose(module: .syncedStore, "receive partial update \(name), \(partialValue)")
        if name == deviceStateName {
            syncStore.getStorageState(name) { [weak self] value in
                guard let self = self else { return }
                let res = (value as? [String: Any])?.compactMapValues { object -> DeviceState? in
                    if let object = object as? NSDictionary {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)
                            let state = try JSONDecoder().decode(DeviceState.self, from: data)
                            return state
                        }
                        catch {
                            Log.error(module: .syncedStore, "device state synced store update error: \(error)")
                        }
                    }
                    return nil
                }
                if let res = res {
                    self.delegate?.flatSyncedStoreDidReceiveCommand(self, command: .deviceStateUpdate(res))
                }
            }
        }
        if name == classroomStateName {
            for partial in partialValue {
                if let key = partial.key as? String,
                   let roomStateKey = RoomState.Keys(rawValue: key) {
                    switch roomStateKey {
                    case .classMode:
                        // TBD: Check Decode
                        if let dic = partial.value as? NSDictionary,
                           let modeString = dic[newValueKey] as? String {
                            let newMode = ClassroomMode(rawValue: modeString)
                            delegate?.flatSyncedStoreDidReceiveCommand(self, command: .classroomModeUpdate(newMode))
                        }
                    case .raiseHandUsers:
                        if let dic = partial.value as? NSDictionary,
                           let raiseHandUserIds = dic[newValueKey] as? [String] {
                            delegate?.flatSyncedStoreDidReceiveCommand(self, command: .raiseHandUsersUpdate(raiseHandUserIds))
                        }
                    case .ban:
                        if let dic = partial.value as? NSDictionary,
                           let isBan = dic[newValueKey] as? Bool {
                            delegate?.flatSyncedStoreDidReceiveCommand(self, command: .banUpdate(isBan))
                        }
                    case .onStageUsers:
                        syncStore.getStorageState(name) { [weak self] value in
                            guard let self = self else { return }
                            if let dic = ((value as? [String: Any])?[roomStateKey.rawValue] as? [String: Any]) {
                                let res = dic.compactMapValues { $0 as? Bool }
                                self.delegate?.flatSyncedStoreDidReceiveCommand(self, command: .onStageUsersUpdate(res))
                            }
                        }
                    }
                }
            }
        }
    }
}
