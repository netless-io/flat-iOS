//
//  WhiteBoardViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Whiteboard

class WhiteboardViewController: UIViewController {
    weak var delegate: WhiteboardViewControllerDelegate?
    var sdk: WhiteSDK!
    var room: WhiteRoom!
    let roomPlayInfo: RoomPlayInfo
    var isRoomJoined = false
    
    let panelOperations: [WhiteBoardOperation] = [
        .updateAppliance(name: .ApplianceClicker),
        .updateAppliance(name: .ApplianceSelector),
        .updateAppliance(name: .AppliancePencil),
        .updateAppliance(name: .ApplianceRectangle),
        .updateAppliance(name: .ApplianceEllipse),
        .updateAppliance(name: .ApplianceText),
        .updateAppliance(name: .ApplianceEraser),
        .updateAppliance(name: .ApplianceLaserPointer),
        .updateAppliance(name: .ApplianceArrow),
        .updateAppliance(name: .ApplianceStraight),
        .updateAppliance(name: .ApplianceHand),
        .clean
    ]

    // MARK: - Public
    func joinRoom(completion: @escaping ((Error?)->Void)) {
        let payload: [String:String] = ["cursorName": roomPlayInfo.userInfo?.name ?? ""]
        let roomConfig: WhiteRoomConfig = .init(uuid: roomPlayInfo.whiteboardRoomUUID,
                                                roomToken: roomPlayInfo.whiteboardRoomToken, userPayload: payload)
        sdk.joinRoom(with: roomConfig,
                     callbacks: self) { [weak self] success, room, error in
            guard let self = self else { return }
            guard error == nil else { return }
            self.room = room
            self.setupControlBar()
            self.isRoomJoined = true
            completion(error)
        }
    }
    
    func leave() {
        guard isRoomJoined else { return }
        room.disconnect(nil)
        isRoomJoined = false
    }
    
    // MARK: - LifeCycle
    init(roomPlayInfo: RoomPlayInfo) {
        self.roomPlayInfo = roomPlayInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSDK()
    }
    
    // MARK: - Private
    func setupViews() {
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func updateColorPickIndicatorButton(withColor color: UIColor) {
        let normalImage = UIImage.pickerItemImage(withColor: color, size: .init(width: 18, height: 18), radius: 9)
        colorPickIndicatorButton.setImage(normalImage, for: .normal)
        
        if let normalImage = normalImage {
            let bg = UIImage.pointWith(color: .controlSelectedBG, size: .init(width: 30, height: 30), radius: 5)
            let selectedImage = bg.compose(normalImage)
            colorPickIndicatorButton.setImage(selectedImage, for: .selected)
        }
    }
    
    @objc func syncToolBarWith(memberState: WhiteReadonlyMemberState) {
        let colorArr = memberState.strokeColor
        let color = UIColor(numberArray: colorArr)
        updateColorPickIndicatorButton(withColor: color)
        applicanceIndicatorButton.updateAppliance(memberState.currentApplianceName)
    }
    
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
    
    // MARK: - Action
    @objc func onClickUndo() {
        room.undo()
    }
    
    @objc func onClickRedo() {
        room.redo()
    }
    
    @objc func onClickMoreAppliance(_ sender: UIButton) {
        popoverViewController(viewController: appliancePickerController, fromSource: sender, permittedArrowDirections: .left)
    }
    
    @objc func onClickColor(_ sender: UIButton) {
        sender.isSelected = true
        popoverViewController(viewController: colorPickerController, fromSource: sender, permittedArrowDirections: .left)
    }
    
    // MARK: - Private
    func setupSDK() {
        let sdkConfig = WhiteSdkConfiguration(app: Env().netlessAppId)
        sdkConfig.renderEngine = .canvas
//        sdkConfig.useMultiViews = true
        sdkConfig.region = .CN
//        sdkConfig.log = true
        sdkConfig.userCursor = true
        sdk = WhiteSDK(whiteBoardView: whiteboardView, config: sdkConfig, commonCallbackDelegate: self)
    }
    
    func setupControlBar() {
        view.addSubview(toolStackView)
        toolStackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Lazy
    lazy var colorPickerController: StrokePickerViewController = {
        let currentColor = UIColor(numberArray: room.memberState.strokeColor)
        let strokeWidth = room.memberState.strokeWidth?.floatValue ?? 0
        let vc = StrokePickerViewController(selectedColor: currentColor, lineWidth: strokeWidth)
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.colorPickIndicatorButton.isSelected = false
            let lineWidth = self.colorPickerController.lineWidth
            let selectedColor = self.colorPickerController.selectedColor
            self.setMemberStateWith(strokeWidth: lineWidth, strokeColor: selectedColor, appliance: nil)
        }
        vc.delegate = self
        return vc
    }()
    
    lazy var appliancePickerController: AppliancePickerViewController = {
        let current = room.memberState.currentApplianceName
        let images = panelOperations.map { $0.buttonImage! }
        let selectedIndex = panelOperations.firstIndex(where: {
            if case .updateAppliance(name: let key) = $0, key == current {
                return true
            }
            return false
        })
        let vc = AppliancePickerViewController(applianceImages: images, selectedIndex: selectedIndex)
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            if let index = self.appliancePickerController.selectedIndex {
                let operation = self.panelOperations[index]
                if case .updateAppliance(name: let name) = operation {
                    self.setMemberStateWith(appliance: name)
                }
            }
        }
        vc.delegate = self
        return vc
    }()
    
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        // handle keyboard by IQKeyboardManager
        view.disableKeyboardHandler = true
        return view
    }()
    
    lazy var colorPickIndicatorButton: UIButton = {
        let button = IndicateMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(onClickColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var applicanceIndicatorButton: IndicateMoreButton = {
        let button = IndicateMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        button.updateAppliance(.ApplianceArrow)
        button.isSelected = true
        button.addTarget(self, action: #selector(onClickMoreAppliance(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "whiteboard_undo"), for: .normal)
        button.addTarget(self, action: #selector(onClickUndo), for: .touchUpInside)
        return button
    }()
    
    lazy var redoButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "whiteboard_redo"), for: .normal)
        button.addTarget(self, action: #selector(onClickRedo), for: .touchUpInside)
        return button
    }()
    
    lazy var toolStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [undoRedoOperationBar, operationBar])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        return stackView
    }()
    
    lazy var undoRedoOperationBar: RoomControlBar = {
        return RoomControlBar(direction: .vertical, borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner], buttons: [undoButton, redoButton])
    }()
    
    lazy var operationBar: RoomControlBar = {
        return RoomControlBar(direction: .vertical,
                              borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner],
                              buttons: [colorPickIndicatorButton, applicanceIndicatorButton])
    }()
}

extension WhiteboardViewController: WhiteCommonCallbackDelegate {
    func throwError(_ error: Error) {
        delegate?.whiteboadViewController(self, error: error)
        print(error)
    }
    
    func sdkSetupFail(_ error: Error) {
        delegate?.whiteboadViewController(self, error: error)
        print(error)
    }
}

extension WhiteboardViewController: WhiteRoomCallbackDelegate {
    func firePhaseChanged(_ phase: WhiteRoomPhase) {
        delegate?.whiteboardViewControllerDidUpdatePhase(self, phase: phase)
        print(#function, phase.rawValue)
    }
    
    func fireRoomStateChanged(_ modifyState: WhiteRoomState!) {
        if let memberState = modifyState.memberState {
            syncToolBarWith(memberState: memberState)
        }
//        print(modifyState)
    }
    
    func fireDisconnectWithError(_ error: String!) {
        delegate?.whiteboadViewController(self, error: error)
        print(error)
    }
    
    func fireKicked(withReason reason: String!) {
        delegate?.whiteboadViewController(self, error: reason)
        print(reason)
    }
    
    func fireCatchError(whenAppendFrame userId: UInt, error: String!) {
        print(userId)
    }
    
    func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        redoButton.isEnabled = canRedoSteps > 0
    }
    
    func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        undoButton.isEnabled = canUndoSteps > 0
    }
}

extension WhiteboardViewController: StrokePickerViewControllerDelegate {
    func strokePickerViewControllerDidUpdateSelectedColor(_ controller: StrokePickerViewController, selectedColor: UIColor) {
        updateColorPickIndicatorButton(withColor: selectedColor)
    }
    
    func strokePickerViewControllerDidUpdateStrokeLineWidth(_ controller: StrokePickerViewController, lineWidth: Float) {
        
    }
}

extension WhiteboardViewController: AppliancePickerViewControllerDelegate {
    func appliancePickerViewControllerDidSelectAppliance(_ controller: AppliancePickerViewController, index: Int) {
        let operation = panelOperations[index]
        if case .updateAppliance(name: let name) = operation {
            applicanceIndicatorButton.updateAppliance(name)
        }
    }
    
    func appliancePickerViewControllerShouldSelectAppliance(_ controller: AppliancePickerViewController, index: Int) -> Bool {
        let operation = panelOperations[index]
        if case .clean = operation {
            room.cleanScene(true)
            return false
        }
        return true
    }
}
