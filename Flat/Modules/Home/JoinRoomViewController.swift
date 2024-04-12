//
//  JoinRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class JoinRoomViewController: UIViewController {
    let deviceStatusStore: UserDevicePreferredStatusStore

    // MARK: - LifeCycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        deviceStatusStore = UserDevicePreferredStatusStore(userUUID: AuthStore.shared.user?.userUUID ?? "")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .formSheet
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        guard !fireKeyboardFirstTime else { return }
        if view.window != nil, view.bounds.width > 0 {
            fireKeyboardFirstTime = true
            roomIdTextField.becomeFirstResponder()
        }
    }

    var fireKeyboardFirstTime = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        historyPickerButton.isEnabled = !ClassroomCoordinator.shared.updateJoinRoomHistoryItem().isEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindJoinEnable()
        setupJoinRoomInputAccessView()
        simulatorUserDeviceStateSelect()
    }

    // MARK: - Action

    @objc func onClickJoin(_ sender: UIButton) {
        guard let uuid = roomIdTextField.text?.ignoreWhiteSpace(),
                !uuid.isEmpty
        else { return }
        
        // Update prefer device status
        let deviceStatus = DeviceState(mic: deviceView.micOn, camera: deviceView.cameraOn)
        deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: deviceStatus.camera)
        deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: deviceStatus.mic)
        
        ClassroomCoordinator.shared.enterClassroom(uuid: uuid,
                                                   periodUUID: nil,
                                                   basicInfo: nil,
                                                   sender: sender)
    }

    // MARK: - Private
    func bindJoinEnable() {
        roomIdTextField.rx.text.orEmpty.asDriver()
            .map(\.isNotEmptyOrAllSpacing)
            .drive(with: self, onNext: { weakSelf, joinEnable in
                weakSelf.joinButton.isEnabled = joinEnable
                weakSelf.roomInputAccessView.enterEnable = joinEnable
            })
            .disposed(by: rx.disposeBag)
    }

    func simulatorUserDeviceStateSelect() {
        // Simulator click to fire permission alert
        let cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        let micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        if cameraOn {
            deviceView.onButtonClick(deviceView.cameraButton)
        }
        if micOn {
            deviceView.onButtonClick(deviceView.microphoneButton)
        }
    }

    func setupViews() {
        addPresentCloseButton()
        addPresentTitle(localizeStrings("Join Room"))
        view.backgroundColor = .color(type: .background)

        let bottomStackItemHeight: CGFloat = 44

        if traitCollection.hasCompact {
            let centerStack = UIStackView(arrangedSubviews: [roomIdTextField, previewView, deviceView])
            centerStack.axis = .vertical
            centerStack.alignment = .center
            centerStack.distribution = .equalCentering
            view.addSubview(centerStack)
            centerStack.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            roomIdTextField.snp.makeConstraints { make in
                make.width.equalTo(320)
                make.height.equalTo(66)
            }

            previewView.snp.makeConstraints { make in
                make.height.equalTo(previewView.snp.width)
                make.width.equalToSuperview().priority(.medium)
                make.width.greaterThanOrEqualTo(280)
            }
            previewView.transform = .init(scaleX: 0.95, y: 0.95)

            view.addSubview(joinButton)
            joinButton.snp.makeConstraints { make in
                make.height.equalTo(bottomStackItemHeight)
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            }
            return
        }

        let bottomStack = UIStackView(arrangedSubviews: [deviceView, joinButton])
        let verticalStack = UIStackView(arrangedSubviews: [roomIdTextField, previewView, bottomStack])
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .equalCentering
        view.addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 56, left: 16, bottom: 16, right: 16))
        }

        roomIdTextField.setContentHuggingPriority(.defaultLow, for: .vertical)
        roomIdTextField.snp.makeConstraints { make in
            make.width.equalTo(320)
            make.height.equalTo(66)
        }

        previewView.snp.makeConstraints { make in
            make.width.equalTo(previewView.snp.height).multipliedBy(16.0 / 9)
            make.width.equalToSuperview().priority(.medium)
            make.width.greaterThanOrEqualTo(280)
        }
        previewView.transform = .init(scaleX: 0.9, y: 0.9)

        bottomStack.axis = .horizontal
        bottomStack.spacing = traitCollection.hasCompact ? 8 : 16
        bottomStack.distribution = .equalCentering
        bottomStack.alignment = .center
        bottomStack.snp.makeConstraints { make in
            make.height.equalTo(bottomStackItemHeight)
        }
        joinButton.snp.makeConstraints { make in
            make.height.equalTo(bottomStackItemHeight)
        }

        preferredContentSize = .init(width: 480, height: 424)
    }

    // MARK: - Lazy

    lazy var roomIdTextField: BottomLineTextfield = {
        var tf = BottomLineTextfield()
        tf.textColor = .color(type: .text, .strong)
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 20)
        tf.placeholder = localizeStrings("Room ID Input PlaceHolder")
        tf.keyboardType = .numberPad
        tf.returnKeyType = .join
        tf.clearButtonMode = .whileEditing
        tf.rightView = historyPickerButton
        tf.rightViewMode = .unlessEditing
        tf.delegate = self
        tf.iq.distanceFromKeyboard = 188
        return tf
    }()
    
    lazy var historyPickerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.frame = .init(x: 0, y: 0, width: 44, height: 44)
        btn.setImage(UIImage(named: "triangle_down"), for: .normal)
        btn.tintColor = .color(type: .text)
        btn.addTarget(self, action: #selector(onClickHistory), for: .touchUpInside)
        return btn
    }()
    
    @objc func onClickHistory() {
        let vc = HistoryJoinRoomPickerViewController()
        vc.roomIdConfirmHandler = { [weak self] id in
            self?.roomIdTextField.text = id
            self?.roomIdTextField.sendActions(for: .editingChanged)
        }
        vc.dismissHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: true)
    }

    @objc func handle(keyboardShowNotification notification: Notification) {
        guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        guard let window = view.window else { return }
        let deviceEnd = deviceView.convert(CGPoint(x: 0, y: deviceView.bounds.height), to: window).y
        let isOverDeviceView = keyboardRect.origin.y > deviceEnd
        if isOverDeviceView, roomIdTextField.inputAccessoryView == roomInputAccessView {
            roomIdTextField.inputAccessoryView = nil
            UIView.performWithoutAnimation {
                self.roomIdTextField.reloadInputViews()
            }
        } else if !isOverDeviceView, roomIdTextField.inputAccessoryView == nil {
            roomIdTextField.inputAccessoryView = roomInputAccessView
            UIView.performWithoutAnimation {
                self.roomIdTextField.reloadInputViews()
            }
        }
    }

    func setupJoinRoomInputAccessView() {
        NotificationCenter.default.addObserver(self, selector: #selector(handle(keyboardShowNotification:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        roomInputAccessView.deviceStateView.delegate = deviceAutorizationHelper
        roomInputAccessView.deviceStateView.cameraOnUpdate = { [weak self] camera in
            self?.deviceView.set(cameraOn: camera)
            self?.previewView.turnCamera(on: camera)
        }
        roomInputAccessView.deviceStateView.micOnUpdate = { [weak self] micOn in
            self?.deviceView.set(micOn: micOn)
        }
        // Hide join for iPad, because of the keyboard return type
        roomInputAccessView.joinButton.isHidden = !traitCollection.hasCompact
        roomInputAccessView.enterHandler = onClickJoin(_:)
    }

    lazy var roomInputAccessView = JoinRoomInputAccessView(cameraOn: deviceView.cameraOn,
                                                           micOn: deviceView.micOn,
                                                           enterTitle: localizeStrings("Join"))

    lazy var joinButton: UIButton = {
        let btn = FlatGeneralCrossButton(type: .custom)
        btn.setTitle(localizeStrings("Join"), for: .normal)
        btn.addTarget(self, action: #selector(onClickJoin(_:)), for: .touchUpInside)
        return btn
    }()

    lazy var previewView = CameraPreviewView()

    lazy var deviceView: CameraMicToggleView = {
        let view = CameraMicToggleView(cameraOn: false, micOn: false)
        view.delegate = deviceAutorizationHelper
        view.cameraOnUpdate = { [weak self] camera in
            self?.roomInputAccessView.cameraOn = camera
            self?.previewView.turnCamera(on: camera)
        }
        view.micOnUpdate = { [weak self] mic in
            self?.roomInputAccessView.micOn = mic
        }
        return view
    }()

    lazy var deviceAutorizationHelper = DeviceAutorizationHelper(rootController: self)
}

extension JoinRoomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onClickJoin(joinButton)
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn _: NSRange, replacementString string: String) -> Bool {
        if let uuid = string.getRoomUuidFromLink(), uuid.count > 8 { // Paste from pastBoard.
            textField.text = uuid
            textField.sendActions(for: .valueChanged)
            return false
        }
        return true
    }
}
