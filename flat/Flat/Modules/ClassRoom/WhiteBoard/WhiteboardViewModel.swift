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

class WhiteboardViewModel: NSObject {
    var panelItems: [WhitePanelItem]
    let menuNavigator: WhiteboardMenuNavigator
    let whiteRoomConfig: WhiteRoomConfig
    
    let isRoomJoined: BehaviorRelay<Bool> = .init(value: false)
    
    var sdk: WhiteSDK!
    var room: WhiteRoom! {
        didSet {
            strokeColor.on(.next(UIColor(numberArray: room.memberState.strokeColor)))
            strokeWidth.on(.next(room.memberState.strokeWidth?.floatValue ?? 1))
            // enable serialization to enable undo, redo
            room.disableSerialization(false)
        }
    }
    
    let redoEnable: BehaviorRelay<Bool> = .init(value: false)
    let undoEnable: BehaviorRelay<Bool> = .init(value: false)
    
    let strokeColor: BehaviorSubject<UIColor> = .init(value: .white)
    let strokeWidth: BehaviorSubject<Float> = .init(value: 1)
    let status: BehaviorRelay<WhiteRoomPhase> = .init(value: WhiteRoomPhase.disconnecting)
    let errorSignal = PublishRelay<Error>()
    fileprivate let scene: BehaviorRelay<WhiteSceneState> = .init(value: .init())
    
    deinit {
        print(self, "deinit")
    }
    
    struct Input {
        let panelTap: Driver<WhitePanelItem>
        let undoTap: Driver<Void>
        let redoTap: Driver<Void>
    }
    
    struct Output {
        let join: Observable<WhiteRoom>
        let selectedItem: Observable<WhitePanelItem?>
        let actions: Observable<WhiteboardPanelOperation?>
        let undo: Observable<Void>
        let redo: Observable<Void>
        let colorAndWidth: Observable<(UIColor, Float)>
        let subMenuPresent: Observable<Void>
    }
    
    init(panelItems: [WhitePanelItem],
         whiteRoomConfig: WhiteRoomConfig,
         menuNavigator: WhiteboardMenuNavigator) {
        self.panelItems = panelItems
        self.menuNavigator = menuNavigator
        self.whiteRoomConfig = whiteRoomConfig
        super.init()
    }
    
    struct SceneInput {
        let previousTap: Driver<Void>
        let nextTap: Driver<Void>
        let newTap: Driver<Void>
    }
    struct SceneOutput {
        let sceneTitle: Driver<String>
        let previousEnable: Driver<Bool>
        let nextEnable: Driver<Bool>
        let taps: Driver<Void>
    }
    func transformSceneInput(_ input: SceneInput) -> SceneOutput {
        let ds = scene.asDriver()
        
        let sceneTitle = ds.map { "\($0.index + 1)/\($0.scenes.count)" }
        let previousEnable = ds.map { $0.index > 0 }
        let nextEnable = ds.map { $0.index + 1 < $0.scenes.endIndex }
        
        let pTap = input.previousTap.do(onNext: { [unowned self] in
            self.room.pptPreviousStep() })
        
        let nextTap = input.nextTap.do(onNext: { [unowned self] in
            self.room.pptNextStep()
        })
        
        let newTap = input.newTap.do(onNext: { [unowned self] in
            let index = self.scene.value.index
            let nextIndex = UInt(index + 1)
            self.room.putScenes("/", scenes: [WhiteScene()], index: nextIndex)
            self.room.setSceneIndex(nextIndex, completionHandler: nil)
        })
        
        let taps = Driver.of(pTap, newTap, nextTap).merge()
        
        return .init(sceneTitle: sceneTitle,
                     previousEnable: previousEnable,
                     nextEnable: nextEnable,
                     taps: taps)
    }
    
    func transform(_ input: Input) -> Output {
        let joinRoom = joinRoom().asObservable().share(replay: 1, scope: .whileConnected)
        
        let initPanelItem = joinRoom.flatMap { [weak self] room -> Observable<WhitePanelItem?> in
            guard let self = self else {
                return .error("self not exist")
            }
            if let initName = room.state.memberState?.currentApplianceName {
                let initPanelItem = self.panelItems.first(where: { $0.contains(operation: .appliance(initName))})
                return .just(initPanelItem)
            } else {
                return .just(nil)
            }
        }
        
        let selectableTap = input.panelTap.asObservable().filter { $0.selectable }.map { [weak self] tap -> WhitePanelItem? in
            guard let self = self, let room = self.room else { return nil }
            switch tap {
            case .single(let op):
                op.execute(inRoom: room)
            case .subOps(_, current: let op):
                op?.execute(inRoom: room)
            default:
                break
            }
            return tap
        }
        
        let subMenuItem = menuNavigator.getNewApplianceObserver().map { [weak self] name -> WhitePanelItem? in
            guard let self = self, let room = self.room else { return nil }
            let op = WhiteboardPanelOperation.appliance(name)
            op.execute(inRoom: room)
            if let index = self.panelItems.firstIndex(where: { $0.contains(operation: op) }) {
                return self.panelItems[index]
            }
            return nil
        }
        
        let initColorAndWidth = joinRoom.map { room -> (UIColor, Float) in
            if let initColor = room.state.memberState?.strokeColor {
                let color = UIColor.init(numberArray: initColor)
                let width = (room.state.memberState?.strokeWidth ?? 0).floatValue
                return (color, width)
            } else {
                return (.black, 1)
            }
        }
        
        let selectedColorAndWidth = menuNavigator.getColorAndWidthObserver().do(onNext: { [weak self] color, width in
            if let room = self?.room {
                let newState = WhiteMemberState()
                newState.strokeColor = color.getNumersArray()
                newState.strokeWidth = .init(value: width)
                room.setMemberState(newState)
                
                if let index = self?.panelItems.firstIndex(of: .color(displayColor: .gray)) {
                    self?.panelItems[index] = .color(displayColor: color)
                }
            }
        })
                                                                                                   
        let selectColorAndWidthPresent = input.panelTap.asObservable().filter { $0.hasSubMenu && !$0.selectable }.flatMap { [weak self] tap -> Observable<Void> in
            guard let self = self, let room = self.room else { return .just(()) }
            switch tap {
            case .color:
                let lineWidth = room.state.memberState?.strokeWidth?.floatValue ?? 0
                self.menuNavigator.presentColorAndWidthPicker(item: tap, lineWidth: lineWidth)
                return .just(())
            default:
                return .just(())
            }
        }
        
        let appliancePresent = input.panelTap.asObservable().filter { $0.hasSubMenu && $0.selectable }.flatMap { [unowned self] tap -> Observable<Void> in
            self.menuNavigator.presentPicker(item: tap)
            return .just(())
        }
        
        let actions = input.panelTap.asObservable().filter { $0.onlyAction }.map { [weak self] tap -> WhiteboardPanelOperation? in
            switch tap {
            case .single(let op):
                if let room = self?.room {
                    op.execute(inRoom: room)
                }
                return op
            default:
                return nil
            }
        }
        
        let panelItem = Observable.of(initPanelItem,
                                       selectableTap,
                                       subMenuItem)
            .merge()
                
        let undo = input.undoTap.asObservable()
            .do(onNext: { [unowned self] in
                self.room.undo()
                
            })
        let redo = input.redoTap.asObservable()
            .do(onNext: { [unowned self] in
                self.room.redo()
            })
                
        let colorAndWidth = Observable.of(initColorAndWidth, selectedColorAndWidth).merge()
        let subMenuPresent = Observable.of(selectColorAndWidthPresent, appliancePresent).merge()
                
        return .init(join: joinRoom,
                     selectedItem: panelItem,
                     actions: actions,
                     undo: undo,
                     redo: redo,
                     colorAndWidth: colorAndWidth,
                     subMenuPresent: subMenuPresent)
    }
    
    // MARK: - Public
    func joinRoom() -> Single<WhiteRoom> {
        return .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            self.sdk.joinRoom(with: self.whiteRoomConfig,
                              callbacks: self) { [weak self] success, room, error in
                guard let self = self else { return }
                if let error = error {
                    observer(.failure(error))
                    return
                }
                guard let room = room else {
                    observer(.failure("error room without error"))
                    return
                }
                self.room = room
                room.getStateWithResult { [weak self, weak room] state in
                    if let sceneState = state.sceneState {
                        self?.scene.accept(sceneState)
                    }
                    guard let room = room else {
                        observer(.failure("room error"))
                        return
                    }
                    observer(.success(room))
                }
            }
            return Disposables.create()
        }.do(onSuccess: { [weak self] _ in
            self?.isRoomJoined.accept(true)
        }, onError: { [weak self] _ in
            self?.isRoomJoined.accept(false)
        })
    }

    func insertMedia(_ src: URL, title: String) {
        let appParam = WhiteAppParam.createMediaPlayerApp(src.absoluteString, title: title)
        room.addApp(appParam) { msg in }
    }
    
    func insertImg(_ src: URL, imgSize: CGSize) {
        let info = WhiteImageInformation(size: imgSize)
        room.insertImage(info, src: src.absoluteString)
    }
    
    func insertPptx(_ pages: [(url: URL, preview: URL, size: CGSize)], title: String) {
        let scenes = pages.enumerated().map { (index, item) -> WhiteScene in
            let pptPage = WhitePptPage(src: item.url.absoluteString,
                                       preview: item.preview.absoluteString,
                                       size: item.size)
            return WhiteScene(name: (index + 1).description,
                                   ppt: pptPage)
        }
        let appParam = WhiteAppParam.createSlideApp("/" + UUID().uuidString, scenes: scenes, title: title)
        room.addApp(appParam) { _ in }
    }
    
    func insertMultiPages(_ pages: [(url: URL, preview: URL, size: CGSize)], title: String) {
        let scenes = pages.enumerated().map { (index, item) -> WhiteScene in
            let pptPage = WhitePptPage(src: item.url.absoluteString,
                                       preview: item.preview.absoluteString,
                                       size: item.size)
            return WhiteScene(name: (index + 1).description,
                                   ppt: pptPage)
        }
        let appParam = WhiteAppParam.createDocsViewerApp("/" + UUID().uuidString, scenes: scenes, title: title)
        room.addApp(appParam) { _ in }
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
        errorSignal.accept(error)
        print("whiteboard throw error", error)
    }
    
    func sdkSetupFail(_ error: Error) {
        errorSignal.accept(error)
        print("setup whiteboard sdk error", error)
    }
}

extension WhiteboardViewModel: WhiteRoomCallbackDelegate {
    func firePhaseChanged(_ phase: WhiteRoomPhase) {
        status.accept(phase)
        print(#function, phase.rawValue)
    }
    
    func fireRoomStateChanged(_ modifyState: WhiteRoomState!) {
        if let memberState = modifyState.memberState {
            if let stokeWidth = memberState.strokeWidth?.floatValue {
                strokeWidth.on(.next(stokeWidth))
            }
            strokeColor.on(.next(UIColor(numberArray: memberState.strokeColor)))
        }
        
        if let scene = modifyState.sceneState {
            self.scene.accept(scene)
        }
    }
    
    func fireDisconnectWithError(_ error: String!) {
        errorSignal.accept(error)
        print("whiteboard disconnect error", error ?? "")
    }
    
    func fireKicked(withReason reason: String!) {
        errorSignal.accept(reason)
        print("whiteboard kicked error", reason ?? "")
    }
    
    func fireCatchError(whenAppendFrame userId: UInt, error: String!) {
        print(#function, userId, error as Any)
    }
    
    func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        redoEnable.accept(canRedoSteps > 0)
    }
    
    func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        undoEnable.accept(canUndoSteps > 0)
    }
}

