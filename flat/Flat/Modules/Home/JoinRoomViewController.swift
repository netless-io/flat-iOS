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
    
    var cameraOn: Bool {
        didSet {
            cameraButton.isSelected = cameraOn
        }
    }
    
    var micOn: Bool {
        didSet {
            micButton.isSelected = micOn
        }
    }
    
    // MARK: - LifeCycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        deviceStatusStore = UserDevicePreferredStatusStore(userUUID: AuthStore.shared.user?.userUUID ?? "")
        self.cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        self.micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fillTextfieldWithPasterBoard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindJoinEnable()
    }
    
    // MARK: - Action
    @objc func onClickCamera(_ sender: UIButton) {
        cameraOn = !cameraOn
    }
    
    @objc func onClickMic(_ sender: UIButton) {
        micOn = !micOn
    }
    
    @objc func onJoin(_ sender: UIButton) {
        guard let uuid = subjectTextField.text, !uuid.isEmpty else {
            return
        }
        
        sender.isEnabled = false
        let playInfo = RoomPlayInfo.fetchByJoinWith(uuid: uuid).share(replay: 1, scope: .whileConnected)
        let roomInfo = playInfo.flatMap { info in
            return RoomInfo.fetchInfoBy(uuid: info.roomUUID)
        }
        Observable.zip(playInfo, roomInfo)
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, tuple in
                sender.isEnabled = true
                let playInfo = tuple.0
                let roomInfo = tuple.1
                let deviceStatus = ClassRoomFactory.DeviceStatus(mic: weakSelf.micOn, camera: weakSelf.cameraOn)
                let vc = ClassRoomFactory.getClassRoomViewController(withPlayInfo: playInfo,
                                                                     detailInfo: roomInfo,
                                                                     deviceStatus: deviceStatus)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: deviceStatus.camera)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: deviceStatus.mic)
                weakSelf.mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            }, onFailure: { weakSelf, error in
                sender.isEnabled = true
                weakSelf.showAlertWith(message: error.localizedDescription)
            }, onDisposed: { _ in
                return
            })
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Private
    func fillTextfieldWithPasterBoard() {
        guard (subjectTextField.text ?? "").isEmpty else { return }
        if let str = UIPasteboard.general.string, !str.isEmpty {
            if let r = try? str.matchExpressionPattern("(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"),
                let url = URL(string: r) {
                let id = url.lastPathComponent
                subjectTextField.text = id
            } else {
                subjectTextField.text = str
            }
            subjectTextField.sendActions(for: .valueChanged)
        }
    }
    
    func bindJoinEnable() {
        subjectTextField.rx.text.orEmpty.asDriver()
            .map { $0.isNotEmptyOrAllSpacing }
            .drive(joinButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        navigationItem.title = NSLocalizedString("Join Room", comment: "")
        view.backgroundColor = .whiteBG
        let topLabel = UILabel()
        topLabel.font = .systemFont(ofSize: 14)
        topLabel.textColor = .subText
        topLabel.text = NSLocalizedString("Room Number", comment: "")
        
        let joinOptionsLabel = UILabel()
        joinOptionsLabel.font = .systemFont(ofSize: 14)
        joinOptionsLabel.textColor = .subText
        joinOptionsLabel.text = NSLocalizedString("Join Options", comment: "")
        
        view.addSubview(topLabel)
        view.addSubview(subjectTextField)
        view.addSubview(joinButton)
        view.addSubview(joinOptionsLabel)
        view.addSubview(cameraButton)
        view.addSubview(micButton)
        
        let margin: CGFloat = 16
        topLabel.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide).inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(margin)
        }
        subjectTextField.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(46)
            make.height.equalTo(48)
        }
        
        joinOptionsLabel.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide).inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(110)
        }
        
        cameraButton.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(135)
        }
        
        micButton.snp.makeConstraints { make in
            make.left.equalTo(cameraButton.snp.right).offset(12)
            make.top.equalTo(cameraButton)
        }
        
        joinButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide).inset(margin)
            make.centerY.equalTo(cameraButton)
            make.height.equalTo(32)
        }
    }
    
    // MARK: - Lazy
    lazy var subjectTextField: UITextField = {
        let tf = UITextField()
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.layer.borderWidth = 1 / UIScreen.main.scale
        tf.layer.cornerRadius = 4
        tf.clipsToBounds = true
        tf.textColor = .text
        tf.font = .systemFont(ofSize: 14)
        tf.placeholder = NSLocalizedString("Room Number Input PlaceHolder", comment: "")
        tf.leftView = .init(frame: .init(origin: .zero, size: .init(width: 10, height: 20)))
        tf.leftViewMode = .always
        tf.keyboardType = .numberPad
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    lazy var joinButton: UIButton = {
        let btn = FlatGeneralButton(type: .custom)
        btn.setTitle(NSLocalizedString("Join", comment: ""), for: .normal)
        btn.addTarget(self, action: #selector(onJoin(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var cameraButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.tintColor = .white
        btn.setImage(UIImage(named: "checklist_normal"), for: .normal)
        btn.setImage(UIImage(named: "checklist_selected"), for: .selected)
        btn.adjustsImageWhenHighlighted = false
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.subText, for: .normal)
        btn.setTitle("  " + NSLocalizedString("Open Camera", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.addTarget(self, action: #selector(onClickCamera(_:)), for: .touchUpInside)
        btn.isSelected = cameraOn
        return btn
    }()
    
    lazy var micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.tintColor = .white
        btn.setImage(UIImage(named: "checklist_normal"), for: .normal)
        btn.setImage(UIImage(named: "checklist_selected"), for: .selected)
        btn.adjustsImageWhenHighlighted = false
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.subText, for: .normal)
        btn.setTitle("  " + NSLocalizedString("Open Mic", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.addTarget(self, action: #selector(onClickMic(_:)), for: .touchUpInside)
        btn.isSelected = micOn
        return btn
    }()
}
