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
import RxCocoa
import SwiftUI

class WhiteboardViewModel: NSObject {
    let toolNavigator: WhiteboardToolNavigator!
    let whiteRoomConfig: WhiteRoomConfig
    
    let isRoomJoined: BehaviorRelay<Bool> = .init(value: false)
    
    var sdk: WhiteSDK!
    var room: WhiteRoom! {
        didSet {
            strokeColor.on(.next(UIColor(numberArray: room.memberState.strokeColor)))
            strokeWidth.on(.next(room.memberState.strokeWidth?.floatValue ?? 1))
        }
    }
    
    let redoEnable: BehaviorRelay<Bool> = .init(value: false)
    let undoEnable: BehaviorRelay<Bool> = .init(value: false)
    
    let strokeColor: BehaviorSubject<UIColor> = .init(value: .white)
    let strokeWidth: BehaviorSubject<Float> = .init(value: 1)
    let status: PublishSubject<WhiteRoomPhase> = .init()
    
    init(whiteRoomConfig: WhiteRoomConfig,
         whiteboardToolNavigator: WhiteboardToolNavigator) {
        self.toolNavigator = whiteboardToolNavigator
        self.whiteRoomConfig = whiteRoomConfig
        super.init()
    }
    
    func transformInput(trigger: Driver<Void>,
                        undoTap: Driver<Void>,
                        redoTap: Driver<Void>,
                        applianceTap: Driver<Void>,
                        strokeTap: Driver<Void>
    ) -> (join: Observable<Void>,
          taps: Driver<Void>,
          appliance: Driver<WhiteApplianceNameKey>,
          strokeValue: Driver<(UIColor, Float)>) {
        let join = trigger.asObservable()
            .flatMap { self.joinRoom() }
        
        _ = undoTap.do(onNext: { [unowned self] in
            self.room.undo()
        })
        _ = redoTap.do(onNext: { [unowned self] in
            self.room.redo()
        })
            
        let stokeValue = strokeTap.asObservable()
            .flatMap { [unowned self] _ -> Driver<(UIColor, Float)> in
                let state = self.room.state.memberState
                let color = UIColor(numberArray: state?.strokeColor ?? [])
                let out = self.toolNavigator.presentColorPicker(withCurrentColor: color, currentWidth: (state?.strokeWidth ?? 0).floatValue)
                return out
            }.do(onNext: { [weak self] value in
                let newState = WhiteMemberState()
                newState.strokeWidth = .init(value: value.1)
                newState.strokeColor = value.0.getNumersArray()
                self?.room.setMemberState(newState)
            })
            .asDriver(onErrorJustReturn: (.white, 0))
            
        let applianceManualChange = applianceTap.asObservable().flatMap { [unowned self] _ -> Driver<WhiteBoardOperation> in
            let name = self.room.state.memberState?.currentApplianceName ?? .ApplianceArrow
            return self.toolNavigator.presentAppliancePicker(withSelectedAppliance: name)
        }
        .do(onNext: {
            switch $0 {
            case .updateAppliance(let name):
                let newState = WhiteMemberState()
                newState.currentApplianceName = name
                self.room.setMemberState(newState)
            case .clean:
                self.room.cleanScene(true)
            }
        })
            .filter({
                switch $0 {
                case .clean: return false
                case .updateAppliance: return true
                }
            })
            .map { op -> WhiteApplianceNameKey in
                switch op {
                case .clean: fatalError()
                case .updateAppliance(name: let name):
                    return name
                }
            }

        let initApplianceName = join.map { [weak self] _ -> WhiteApplianceNameKey in
            return self?.room.state.memberState?.currentApplianceName ?? .ApplianceArrow
        }
        
        let appliance = Observable.of(initApplianceName, applianceManualChange)
            .merge()
            .asDriver(onErrorJustReturn: .ApplianceArrow)
        
        let taps = Driver.of(undoTap, redoTap)
            .merge()
        return (join, taps, appliance, stokeValue)
    }
    
    // MARK: - Public
    func joinRoom() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            self.sdk.joinRoom(with: self.whiteRoomConfig,
                              callbacks: self) { [weak self] success, room, error in
                guard let self = self else { return }
                if let error = error {
                    observer.onError(error)
                    return
                }
                self.room = room
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }.do(onCompleted: { [weak self] in
            self?.isRoomJoined.accept(true)
        })
    }
    
    @discardableResult
    func leave() -> Single<Void> {
        guard isRoomJoined.value else { return .just(()) }
        return .create { [weak self] observer in
            self?.room.disconnect({
                observer(.success(()))
            })
            return Disposables.create()
        }
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
        }
    }
    
    func fireDisconnectWithError(_ error: String!) {
        status.onError(error)
        print(#function, error)
    }
    
    func fireKicked(withReason reason: String!) {
        status.onError(reason)
        print(#function, reason)
    }
    
    func fireCatchError(whenAppendFrame userId: UInt, error: String!) {
        print(#function, userId)
    }
    
    func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        redoEnable.accept(canRedoSteps > 0)
    }
    
    func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        undoEnable.accept(canUndoSteps > 0)
    }
}

