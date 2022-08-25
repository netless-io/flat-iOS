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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindJoinEnable()
        
        subjectTextField.becomeFirstResponder()
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
                parent?.dismiss(animated: false)
                parent?.present(vc, animated: true, completion: nil)
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
            .drive(joinButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        addPresentCloseButton()
        addPresentTitle(localizeStrings("Join Room"))
        
        view.backgroundColor = .whiteBG
        view.addSubview(subjectTextField)
        view.addSubview(joinButton)
        view.addSubview(deviceView)
        
        subjectTextField.snp.makeConstraints { make in
            make.width.equalTo(320)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-100)
            make.height.equalTo(30 + 32)
        }
        
        deviceView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(joinButton.snp.top).offset(-32)
        }
        
        joinButton.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(40)
        }
    }
    
    // MARK: - Lazy
    lazy var subjectTextField: BottomLineTextfield = {
        let tf = BottomLineTextfield()
        tf.textColor = .strongText
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 20)
        tf.placeholder = NSLocalizedString("Room Number Input PlaceHolder", comment: "")
        tf.keyboardType = .numberPad
        tf.returnKeyType = .join
        tf.clearButtonMode = .whileEditing
        tf.delegate = self
        return tf
    }()
    
    lazy var joinButton: UIButton = {
        let btn = FlatGeneralCrossButton(type: .custom)
        btn.setTitle(NSLocalizedString("Join", comment: ""), for: .normal)
        btn.addTarget(self, action: #selector(onClickJoin(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var deviceView: CameraMicToggleView = {
        let cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        let micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        let view = CameraMicToggleView(cameraOn: cameraOn, micOn: micOn)
        return view
    }()
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
