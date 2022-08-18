//
//  FastboardViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard
import RxSwift
import RxRelay

class FastboardViewController: UIViewController {
    let fastRoom: FastRoom
    let isRoomJoined: BehaviorRelay<Bool> = .init(value: false)
    let isRoomBanned: BehaviorRelay<Bool> = .init(value: false)
    let roomError: PublishRelay<FastRoomError> = .init()
    
    /// Setup this store after whiteboard joined
    weak var bindStore: ClassRoomSyncedStore?
    var previewHandler: ((WhiteRoom, UIButton)->Void)?
    
    // MARK: Public
    func leave() {
        fastRoom.disconnectRoom()
    }
    
    func updateWritable(_ writable: Bool) -> Single<Bool> {
        guard let w = fastRoom.room?.isWritable else { return .just(writable) }
        if w != writable {
            return .create { [weak self] ob in
                guard let self = self else {
                    ob(.failure("self not exist"))
                    return Disposables.create()
                }
                logger.info("update writable \(writable)")
                self.fastRoom.updateWritable(writable) { error in
                    if let error = error {
                        ob(.failure(error))
                    } else {
                        ob(.success(writable))
                    }
                }
                return Disposables.create()
            }
        } else {
            return .just(writable)
        }
    }
    
    func bind(observableWritable: Observable<Bool>) -> Observable<Bool> {
        Observable.combineLatest(observableWritable, isRoomJoined)
            .filter { $0.1 }
            .map { $0.0 }
            .distinctUntilChanged()
            .concatMap { [weak self]  writable -> Observable<Bool> in
                guard let self = self else { return .error("self not exist")}
                return self.updateWritable(writable).asObservable()
            }.do(onNext: { [weak self] writable in
                self?.fastRoom.setAllPanel(hide: !writable)
            })
    }
    
    init(fastRoomConfiguration: FastRoomConfiguration) {
        self.fastRoom = Fastboard.createFastRoom(withFastRoomConfig: fastRoomConfiguration)
        super.init(nibName: nil, bundle: nil)
        self.fastRoom.delegate = self
        logger.trace("\(self)")
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        logger.trace("\(self), deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        joinRoom()
        bindConnecting()
    }
    
    // MARK: - Private
    func joinRoom() {
        fastRoom.joinRoom { [weak self] result in
            switch result {
            case .success(let room):
                self?.isRoomJoined.accept(true)
                if let relatedStore = self?.bindStore {
                    relatedStore.setup(with: room)
                }
            case .failure:
                return
            }
        }
    }
    
    func bindConnecting() {
        isRoomJoined
            .asDriver()
            .distinctUntilChanged()
            .drive(with: self, onNext: { weakSelf, isJoin in
                if isJoin {
                    weakSelf.stopActivityIndicator()
                } else {
                    weakSelf.showActivityIndicator()
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        view.addSubview(fastRoom.view)
        fastRoom.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let saveItem = JustExecutionItem(image: UIImage(named: "save")!, action: { [weak self] room, value in
            if let button = value as? UIButton {
                self?.previewHandler?(room, button)
            }
        }, identifier: "whiteboard_save")
        RegularFastRoomOverlay.customOptionPanel = {
            var items = RegularFastRoomOverlay.defaultOperationPanelItems
            items.append(saveItem)
            return FastRoomPanel(items: items)
        }
    }
}

extension FastboardViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_ fastboard: FastRoom, room: WhiteRoom) {}
    
    func fastboardUserKickedOut(_ fastboard: FastRoom, reason: String) {
        // For this error is caused by server closing, it should be noticed by teacher.
        isRoomBanned.accept(true)
    }
    
    func fastboardPhaseDidUpdate(_ fastboard: FastRoom, phase: FastRoomPhase) {
        logger.info("phase update \(phase)")
        switch phase {
        case .connecting, .reconnecting, .disconnecting, .disconnected:
            isRoomJoined.accept(false)
        case .connected:
            isRoomJoined.accept(true)
        case .unknown:
            return
        }
    }
    
    func fastboardDidOccurError(_ fastboard: FastRoom, error: FastRoomError) {
        roomError.accept(error)
    }

    func fastboardDidSetupOverlay(_ fastboard: FastRoom, overlay: FastRoomOverlay?) {
        if let overlay = overlay as? RegularFastRoomOverlay {
            overlay.deleteSelectionPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.operationPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.undoRedoPanel.view?.borderMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            overlay.scenePanel.view?.borderMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

            overlay.invalidAllLayout()
            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalTo(fastboard.view.whiteboardView)
                make.left.equalTo(fastboard.view.whiteboardView)
            }
            overlay.deleteSelectionPanel.view?.snp.makeConstraints({ make in
                make.left.equalTo(overlay.operationPanel.view!)
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
            })
            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(fastboard.view.whiteboardView)
                make.left.equalToSuperview().inset(16)
            }
            overlay.scenePanel.view?.snp.makeConstraints { make in
                make.centerX.equalTo(fastboard.view.whiteboardView)
                make.bottom.equalTo(fastboard.view.whiteboardView)
            }
        }
        if let overlay = overlay as? CompactFastRoomOverlay {
            overlay.operationPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.colorAndStrokePanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.deleteSelectionPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.undoRedoPanel.view?.direction = .vertical
            overlay.undoRedoPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

            overlay.setPanelItemHide(item: .operationType(.previousPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.pageIndicator)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.nextPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.newPage)!, hide: true)

            overlay.invalidAllLayout()

            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview()
            }

            overlay.colorAndStrokePanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview()
            }

            overlay.deleteSelectionPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview()
            }

            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalTo(overlay.operationPanel.view!.snp.bottom).offset(8)
            }
        }
    }
}

extension FastRoomPhase: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reconnecting:
            return "reconnecting"
        case .disconnecting:
            return "disconnecting"
        case .disconnected:
            return "disconnected"
        case .unknown:
            return "unknown \(rawValue)"
        }
    }
}
