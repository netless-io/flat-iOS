//
//  JoinRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift

class JoinRoomViewController: UIViewController {
    let deviceStatusStore: UserDevicePreferredStatusStore
    
    // MARK: - LifeCycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        deviceStatusStore = UserDevicePreferredStatusStore(userUUID: AuthStore.shared.user?.userUUID ?? "")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .formSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        subjectTextField.becomeFirstResponder()
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
        guard let uuid = subjectTextField.text?.replacingOccurrences(of: " ", with: ""), !uuid.isEmpty else {
            return
        }
        sender.isEnabled = false
        let playInfo = RoomPlayInfo.fetchByJoinWith(uuid: uuid, periodicUUID: nil).share(replay: 1, scope: .whileConnected)
        let roomInfo = playInfo.flatMap { info in
            return RoomBasicInfo.fetchInfoBy(uuid: info.roomUUID, periodicUUID: nil)
        }
        Observable.zip(playInfo, roomInfo)
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, tuple in
                sender.isEnabled = true
                let playInfo = tuple.0
                let roomInfo = tuple.1
                let deviceStatus = DeviceState(mic: weakSelf.deviceView.micOn, camera: weakSelf.deviceView.cameraOn)
                let vc = ClassroomFactory.getClassRoomViewController(withPlayInfo: playInfo,
                                                                     detailInfo: roomInfo,
                                                                     deviceStatus: deviceStatus)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: deviceStatus.camera)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: deviceStatus.mic)
                let parent = weakSelf.mainContainer?.concreteViewController
                parent?.dismiss(animated: true) {
                    parent?.present(vc, animated: true, completion: nil)
                }
            }, onFailure: { weakSelf, error in
                sender.isEnabled = true
                weakSelf.showAlertWith(message: error.localizedDescription)
            }, onDisposed: { _ in
                return
            })
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Private
    fileprivate func getRoomUUIDFrom(_ str: String) -> String? {
        if !str.isEmpty {
            if let r = try? str.matchExpressionPattern("(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"),
               let url = URL(string: r),
               Env().webBaseURL.contains(url.host ?? "") {
                let id = url.lastPathComponent
                return id
            } else if let num = try? str.matchExpressionPattern("(\\d ?){10}") {
                let r = num.replacingOccurrences(of: " ", with: "")
                return r
            }
        }
        return nil
    }
    
    func bindJoinEnable() {
        subjectTextField.rx.text.orEmpty.asDriver()
            .map { $0.isNotEmptyOrAllSpacing }
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
        
        if isCompact() {
            let centerStack = UIStackView(arrangedSubviews: [subjectTextField, previewView, deviceView])
            centerStack.axis = .vertical
            centerStack.alignment = .center
            centerStack.distribution = .equalCentering
            view.addSubview(centerStack)
            centerStack.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            subjectTextField.snp.makeConstraints { make in
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
        let verticalStack = UIStackView(arrangedSubviews: [subjectTextField, previewView, bottomStack])
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .equalCentering
        view.addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 56, left: 16, bottom: 16, right: 16))
        }
        
        subjectTextField.setContentHuggingPriority(.defaultLow, for: .vertical)
        subjectTextField.snp.makeConstraints { make in
            make.width.equalTo(320)
            make.height.equalTo(66)
        }
        
        previewView.snp.makeConstraints { make in
            make.width.equalTo(previewView.snp.height).multipliedBy(16.0/9)
            make.width.equalToSuperview().priority(.medium)
            make.width.greaterThanOrEqualTo(280)
        }
        previewView.transform = .init(scaleX: 0.9, y: 0.9)
        
        bottomStack.axis = .horizontal
        bottomStack.spacing = isCompact() ? 8 : 16
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
    lazy var subjectTextField: BottomLineTextfield = {
        let tf = BottomLineTextfield()
        tf.textColor = .color(type: .text, .strong)
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 20)
        tf.placeholder = NSLocalizedString("Room Number Input PlaceHolder", comment: "")
        tf.keyboardType = .numberPad
        tf.returnKeyType = .join
        tf.clearButtonMode = .whileEditing
        tf.delegate = self
        tf.keyboardDistanceFromTextField = 188
        return tf
    }()

    @objc func handle(keyboardShowNotification notification: Notification) {
        guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        guard let window = view.window else { return }
        let deviceEnd = deviceView.convert(CGPoint(x: 0, y: deviceView.bounds.height), to: window).y
        let isOverDeviceView = keyboardRect.origin.y > deviceEnd
        if isOverDeviceView, subjectTextField.inputAccessoryView == roomInputAccessView {
            subjectTextField.inputAccessoryView = nil
            UIView.performWithoutAnimation {
                self.subjectTextField.reloadInputViews()
            }
        } else if !isOverDeviceView, subjectTextField.inputAccessoryView == nil {
            subjectTextField.inputAccessoryView = roomInputAccessView
            UIView.performWithoutAnimation {
                self.subjectTextField.reloadInputViews()
            }
        }
    }
    
    func setupJoinRoomInputAccessView() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(keyboardShowNotification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        subjectTextField.inputAccessoryView = roomInputAccessView
        roomInputAccessView.deviceStateView.delegate = deviceAutorizationHelper
        roomInputAccessView.deviceStateView.cameraOnUpdate = { [weak self] camera in
            self?.deviceView.set(cameraOn: camera)
            self?.previewView.turnCamera(on: camera)
        }
        roomInputAccessView.deviceStateView.micOnUpdate = { [weak self] micOn in
            self?.deviceView.set(micOn: micOn)
        }
        // Hide join for iPad, because of the keyboard return type
        roomInputAccessView.joinButton.isHidden = !isCompact()
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let uuid = getRoomUUIDFrom(string) {
            textField.text = uuid
            textField.sendActions(for: .valueChanged)
            return false
        }
        return true
    }
}
