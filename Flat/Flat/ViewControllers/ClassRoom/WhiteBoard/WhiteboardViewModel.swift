//
//  WhiteboardViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/8.
//  Copyright © 2021 agora.io. All rights reserved.
//


import RxSwift
import Whiteboard
import RxRelay

class WhiteboardViewModel: NSObject {
    let panelOperations: [WhiteBoardOperation] = [
        .updateAppliance(name: .ApplianceClicker),
        .updateAppliance(name: .ApplianceSelector),
        .updateAppliance(name: .AppliancePencil),
        .updateAppliance(name: .ApplianceRectangle),
        .updateAppliance(name: .ApplianceEllipse),
        .updateAppliance(name: .ApplianceText),
        .updateAppliance(name: .ApplianceEraser),
//        .updateAppliance(name: .ApplianceLaserPointer),
        .updateAppliance(name: .ApplianceArrow),
        .updateAppliance(name: .ApplianceStraight),
//        .updateAppliance(name: .ApplianceHand),
        .clean
    ]
    
    let userName: String?
    let whiteboardUUID: String
    let whiteboardToken: String
    var isRoomJoined = false
    
    var sdk: WhiteSDK!
    var room: WhiteRoom! {
        didSet {
            strokeColor.on(.next(UIColor(numberArray: room.memberState.strokeColor)))
            strokeWidth.on(.next(room.memberState.strokeWidth?.floatValue ?? 1))
        }
    }
    
    let redoEnableCount: BehaviorRelay<Int> = .init(value: 0)
    let undoEnableCount: BehaviorRelay<Int> = .init(value: 0)
    let strokeColor: BehaviorSubject<UIColor> = .init(value: .white)
    let appliance: BehaviorSubject<WhiteApplianceNameKey> = .init(value: .ApplianceArrow)
    let strokeWidth: BehaviorSubject<Float> = .init(value: 1)
    let status: PublishSubject<WhiteRoomPhase> = .init()
    
    init(uuid: String,
         token: String,
         userName: String?) {
        self.whiteboardUUID = uuid
        self.whiteboardToken = token
        self.userName = userName
    }
    
    // MARK: - Private
    func setMemberStateWith(strokeWidth: Float? = nil,
                            strokeColor: UIColor? = nil,
                            appliance: WhiteApplianceNameKey? = nil) {
        let newState = WhiteMemberState()
        newState.strokeWidth = strokeWidth.map { NSNumber(value: $0) }
        if let strokeColor = strokeColor {
            newState.strokeColor = strokeColor.getNumersArray()
        }
        newState.currentApplianceName = appliance
        room.setMemberState(newState)
    }
    
    // MARK: - Public
    func undo() {
        room.undo()
    }
    
    func redo() {
        room.redo()
    }
    
    func update(stokeWidth: Float?,
                stokeColor: UIColor?,
                appliance: WhiteApplianceNameKey?) {
        if let stokeWidth = stokeWidth {
            strokeWidth.on(.next(stokeWidth))
        }
        if let stokeColor = stokeColor {
            strokeColor.on(.next(stokeColor))
        }
        if let appliance = appliance {
            self.appliance.on(.next(appliance))
        }
        setMemberStateWith(strokeWidth: stokeWidth,
                            strokeColor: stokeColor,
                            appliance: appliance)
    }
    
    func couldPickOperation(index: Int) -> Bool {
        let operation = panelOperations[index]
        if case .clean = operation {
            room.cleanScene(true)
            return false
        }
        return true
    }
    
    func pickOperation(index: Int) {
        let operation = panelOperations[index]
        if case .updateAppliance(name: let name) = operation {
            update(stokeWidth: nil,
                   stokeColor: nil,
                   appliance: name)
        }
    }
    
    func setupWith(_ whiteboardView: WhiteBoardView) {
        let sdkConfig = WhiteSdkConfiguration(app: Env().netlessAppId)
        sdkConfig.renderEngine = .canvas
        sdkConfig.region = .CN
        sdkConfig.userCursor = true
        sdk = WhiteSDK(whiteBoardView: whiteboardView, config: sdkConfig, commonCallbackDelegate: self)
    }
    
    func joinRoom() -> Completable {
        let payload: [String:String] = ["cursorName": userName ?? ""]
        let roomConfig: WhiteRoomConfig = .init(uuid: whiteboardUUID,
                                                roomToken: whiteboardToken,
                                                userPayload: payload)
        return Completable.create { [weak self] subscribe in
            guard let self = self else {
                return Disposables.create()
            }
            self.sdk.joinRoom(with: roomConfig,
                              callbacks: self) { [weak self] success, room, error in
                guard let self = self else { return }
                if let error = error {
                    subscribe(.error(error))
                    return
                }
                self.room = room
                self.isRoomJoined = true
                subscribe(.completed)
            }
            return Disposables.create()
        }
    }
    
    @discardableResult
    func leave() -> Observable<Void> {
        guard isRoomJoined else { return .empty() }
        room.disconnect(nil)
        isRoomJoined = false
        return .empty()
    }
}

extension WhiteboardViewModel: WhiteCommonCallbackDelegate {
    func throwError(_ error: Error) {
        status.onError(error)
        print(error)
    }
    
    func sdkSetupFail(_ error: Error) {
        status.onError(error)
        print(error)
    }
}

extension WhiteboardViewModel: WhiteRoomCallbackDelegate {
    func firePhaseChanged(_ phase: WhiteRoomPhase) {
        status.on(.next(phase))
        print(#function, phase.rawValue)
    }
    
    func fireRoomStateChanged(_ modifyState: WhiteRoomState!) {
        if let memberState = modifyState.memberState {
            if let stokeWidth = memberState.strokeWidth?.floatValue {
                strokeWidth.on(.next(stokeWidth))
            }
            strokeColor.on(.next(UIColor(numberArray: memberState.strokeColor)))
            appliance.on(.next(memberState.currentApplianceName))
        }
    }
    
    func fireDisconnectWithError(_ error: String!) {
        status.onError(error)
        print(error)
    }
    
    func fireKicked(withReason reason: String!) {
        status.onError(reason)
        print(reason)
    }
    
    func fireCatchError(whenAppendFrame userId: UInt, error: String!) {
        print(userId)
    }
    
    func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        redoEnableCount.accept(canRedoSteps)
    }
    
    func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        undoEnableCount.accept(canUndoSteps)
    }
}
