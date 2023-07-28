//
//  FastboardViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import RxRelay
import RxSwift
import ScreenCorners
import SnapKit
import UIKit
import Whiteboard

func tryPreloadWhiteboard() {
    DispatchQueue.main.async {
        // Load once to reduce first time join room
        _ = WhiteBoardView(frame: .zero)
    }
}

struct WhiteboardPermission: Equatable {
    let writable: Bool
    let inputEnable: Bool
}

class FastboardViewController: UIViewController {
    let fastRoom: FastRoom
    let isRoomJoined: BehaviorRelay<Bool> = .init(value: false)
    let isRoomBanned: BehaviorRelay<Bool> = .init(value: false)
    let roomPermission: BehaviorRelay<WhiteboardPermission>
    let roomError: PublishRelay<FastRoomError> = .init()

    /// Setup this store after whiteboard joined
    weak var bindStore: ClassRoomSyncedStore?
    weak var bindLayoutStore: VideoLayoutStoreImp?
    var syncedStoreMultiDelegate = SyncedStoreMultiDelegate()

    var appsClickHandler: ((WhiteRoom, UIButton) -> Void)?

    // MARK: Public

    func insert(image: UIImage, url: URL, changeApplianceToSelector: Bool = true) {
        let imageSize = image.size
        let cameraScale = self.fastRoom.room?.state.cameraState?.scale.floatValue ?? 1
        let containerWidth = self.fastRoom.view.bounds.width / 2.5 / CGFloat(cameraScale)
        if imageSize.width > containerWidth {
            let ratio = imageSize.width / imageSize.height
            self.fastRoom.insertImg(url, imageSize: .init(width: containerWidth, height: containerWidth / ratio))
        } else {
            self.fastRoom.insertImg(url, imageSize: image.size)
        }
        if changeApplianceToSelector {
            let newMemberState = WhiteMemberState()
            newMemberState.currentApplianceName = .ApplianceSelector
            self.fastRoom.room?.setMemberState(newMemberState)
            self.fastRoom.view.overlay?.initUIWith(appliance: .ApplianceSelector, shape: nil)
        }
    }
    
    func leave() {
        fastRoom.disconnectRoom()
    }

    func updateRoomPermission(_ permission: WhiteboardPermission) -> Single<WhiteboardPermission> {
        guard let w = fastRoom.room?.isWritable else { return .just(permission) }
        logger.info("update whiteboard permission \(permission)")
        fastRoom.room?.disableDeviceInputs(!permission.inputEnable)
        if w != permission.writable {
            return .create { [weak self] ob in
                guard let self else {
                    ob(.failure("self not exist"))
                    return Disposables.create()
                }
                logger.info("update writable success \(permission.writable)")
                self.fastRoom.updateWritable(permission.writable) { [weak self] error in
                    if let error {
                        ob(.failure(error))
                    } else {
                        ob(.success(permission))
                        self?.roomPermission.accept(permission)
                        self?.syncUndoRedoGestureEnable()
                    }
                }
                return Disposables.create()
            }
        } else {
            return .just(permission)
        }
    }

    func bind(observablePermission: Observable<WhiteboardPermission>) -> Observable<WhiteboardPermission> {
        Observable.combineLatest(observablePermission, isRoomJoined)
            .filter(\.1)
            .map(\.0)
            .distinctUntilChanged()
            .concatMap { [weak self] permission -> Observable<WhiteboardPermission> in
                guard let self else { return .error("self not exist") }
                return self.updateRoomPermission(permission).asObservable()
            }.do(onNext: { [weak self] permission in
                self?.fastRoom.setAllPanel(hide: !permission.inputEnable)
                self?.fastRoom.room?.disableCameraTransform(!permission.inputEnable)
            })
    }

    init(fastRoomConfiguration: FastRoomConfiguration) {
        fastRoom = Fastboard.createFastRoom(withFastRoomConfig: fastRoomConfiguration)
        roomPermission = .init(value: .init(writable: fastRoomConfiguration.whiteRoomConfig.isWritable,
                                            inputEnable: fastRoomConfiguration.whiteRoomConfig.isWritable))
        super.init(nibName: nil, bundle: nil)
        fastRoom.delegate = self
        logger.trace("\(self)")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        setupGestures()
    }

    var regularUndoLeftMargin: Constraint?
    var regularRightSceneMargin: Constraint?
    let boardMargin: CGFloat = 8

    func updateUndoAndSceneConstraints() {
        if #available(iOS 14.0, *) {
            if ProcessInfo().isiOSAppOnMac { return }
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            let overlay = (fastRoom.view.overlay as? RegularFastRoomOverlay)
            let itemCount = overlay?.operationPanel.items.count ?? 0
            let itemHeight = FastRoomControlBar.appearance().itemWidth
            let minHeight = itemHeight * CGFloat(itemCount + 2)
            if view.bounds.height >= minHeight {
                regularUndoLeftMargin?.update(inset: boardMargin)
                regularRightSceneMargin?.update(inset: boardMargin)
            } else {
                regularUndoLeftMargin?.update(inset: 88)
                regularRightSceneMargin?.update(inset: 88)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // It does not affect whiteboard background color.
        // Only for the device rotate transition
        Theme.shared.whiteboardStyle.whiteboardTraitCollectionDidChangeResolve(traitCollection, fastRoom: fastRoom)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUndoAndSceneConstraints()

        innerBorderMask.frame = view.bounds

        let rectPath = UIBezierPath(rect: view.bounds)

        let lineWidth = CGFloat(3)
        let radius: CGFloat
        if let window = view.window {
            let leftBottom = view.convert(CGPoint(x: 0, y: view.bounds.height), to: window)
            if leftBottom.y == window.bounds.height, leftBottom.x == 0 {
                radius = (view.window?.screen.displayCornerRadius ?? 0)
            } else {
                radius = 0
            }
        } else {
            radius = 0
        }

        let frame = view.bounds.inset(by: .init(inset: lineWidth))
        let roundPath = UIBezierPath(roundedRect: frame,
                                     byRoundingCorners: [.bottomLeft, .bottomRight],
                                     cornerRadii: .init(width: radius, height: radius))

        rectPath.append(roundPath)
        rectPath.usesEvenOddFillRule = true
        innerBorderMask.fillRule = .evenOdd
        innerBorderMask.path = rectPath.cgPath
    }

    // MARK: - Private

    func joinRoom() {
        fastRoom.joinRoom { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(room):
                self.isRoomJoined.accept(true)

                if let relatedStore = self.bindStore {
                    self.syncedStoreMultiDelegate.items.add(relatedStore)
                    relatedStore.setup(with: room)
                }
                if let relatedLayoutStore = self.bindLayoutStore {
                    self.syncedStoreMultiDelegate.items.add(relatedLayoutStore)
                    relatedLayoutStore.setup(whiteboardDisplayer: room)
                }
                room.obtainSyncedStore().delegate = self.syncedStoreMultiDelegate
            case .failure:
                return
            }
        }
    }

    @objc
    fileprivate func onUndoRedoGesture(_ g: UITapGestureRecognizer) {
        if g === undoGesture {
            fastRoom.room?.undo()
        }
        if g === redoGesture {
            fastRoom.room?.redo()
        }
    }

    func syncUndoRedoGestureEnable() {
        let preferDisable = PerferrenceManager.shared.preferences[.disableDefaultUndoRedo] ?? false
        let permissionDisable = !roomPermission.value.inputEnable
        updateUndoRedoGestureDisable(preferDisable || permissionDisable)
    }

    @objc
    fileprivate func onUndoRedoPreferenceUpdate(notification _: Notification) {
        syncUndoRedoGestureEnable()
    }

    fileprivate func updateUndoRedoGestureDisable(_ disabled: Bool) {
        [undoGesture, redoGesture].forEach { $0.isEnabled = !disabled }
    }

    fileprivate func setupGestures() {
        view.addGestureRecognizer(undoGesture)
        view.addGestureRecognizer(redoGesture)
        syncUndoRedoGestureEnable()
        NotificationCenter.default.addObserver(self, selector: #selector(onUndoRedoPreferenceUpdate(notification:)), name: undoRedoPreferenceUpdateNotificaton, object: nil)
    }

    func bindConnecting() {
        Observable.combineLatest(isRoomJoined.asObservable(), isRoomBanned.asObservable()) { join, ban in
            let showLoading = !join && !ban
            return showLoading
        }
        .asDriver(onErrorJustReturn: false)
        .distinctUntilChanged()
        .drive(with: self, onNext: { weakSelf, showLoading in
            if showLoading {
                weakSelf.showActivityIndicator()
            } else {
                weakSelf.stopActivityIndicator()
            }
        })
        .disposed(by: rx.disposeBag)
    }

    func setupViews() {
        if #available(iOS 16.4, *) {
            fastRoom.view.whiteboardView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        view.addSubview(fastRoom.view)
        fastRoom.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.addSubview(blackMaskView)
        blackMaskView.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.addSubview(innerBorderMaskView)
        innerBorderMaskView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let appsItem = JustExecutionItem(image: UIImage(named: "whiteboard_apps")!, action: { [weak self] room, value in
            self?.fastRoom.view.overlay?.dismissAllSubPanels()
            if let button = value as? UIButton {
                self?.appsClickHandler?(room, button)
            }
        }, identifier: "whiteboard_apps")

        RegularFastRoomOverlay.customOperationPanel = {
            var items = RegularFastRoomOverlay.defaultOperationPanelItems
            items.append(appsItem)
            return FastRoomPanel(items: items)
        }
    }

    // MARK: - Lazy

    lazy var undoGesture: UITapGestureRecognizer = {
        let double = UITapGestureRecognizer(target: self, action: #selector(onUndoRedoGesture))
        double.numberOfTouchesRequired = 2
        double.delegate = self
        return double
    }()

    lazy var redoGesture: UITapGestureRecognizer = {
        let triple = UITapGestureRecognizer(target: self, action: #selector(onUndoRedoGesture))
        triple.numberOfTouchesRequired = 3
        triple.delegate = self
        return triple
    }()

    lazy var blackMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()

    lazy var innerBorderMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .color(type: .primary)
        view.isHidden = true
        view.layer.mask = innerBorderMask
        return view
    }()

    lazy var innerBorderMask = CAShapeLayer()
}

extension FastboardViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_: FastRoom, room _: WhiteRoom) {}

    func fastboardUserKickedOut(_: FastRoom, reason _: String) {
        // For this error is caused by server closing, it should be noticed by teacher.
        isRoomBanned.accept(true)
    }

    func fastboardPhaseDidUpdate(_: FastRoom, phase: FastRoomPhase) {
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

    func fastboardDidOccurError(_: FastRoom, error: FastRoomError) {
        roomError.accept(error)
    }

    func fastboardDidSetupOverlay(_ fastboard: FastRoom, overlay: FastRoomOverlay?) {
        if let overlay = overlay as? RegularFastRoomOverlay {
            overlay.invalidAllLayout()
            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalTo(fastboard.view.whiteboardView)
                make.left.equalTo(fastboard.view.whiteboardView).inset(boardMargin)
            }

            overlay.deleteSelectionPanel.view?.snp.makeConstraints { make in
                make.left.equalTo(overlay.operationPanel.view!)
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-boardMargin)
            }

            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(fastboard.view.whiteboardView).inset(boardMargin)
                self.regularUndoLeftMargin = make.left.equalToSuperview().inset(boardMargin).constraint
            }

            overlay.scenePanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(fastboard.view.whiteboardView).inset(boardMargin)
                self.regularRightSceneMargin = make.right.equalToSuperview().inset(boardMargin).constraint
            }
            updateUndoAndSceneConstraints()
        }

        if let overlay = overlay as? CompactFastRoomOverlay {
            overlay.undoRedoPanel.view?.direction = .vertical

            overlay.setPanelItemHide(item: .operationType(.previousPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.pageIndicator)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.nextPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.newPage)!, hide: true)

            overlay.invalidAllLayout()

            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().inset(8)
            }

            overlay.colorAndStrokePanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview().inset(8)
            }

            overlay.deleteSelectionPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview().inset(8)
            }

            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(8)
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

extension FastboardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Reject tap not at current hierachy.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else { return false }
        return touchView.isDescendant(of: fastRoom.view)
    }
}
