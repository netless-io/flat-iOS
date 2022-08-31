//
//  CreateClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift

class CreateClassRoomViewController: UIViewController {
    var availableTypes: [ClassRoomType] = [.bigClass, .smallClass, .oneToOne]
    
    let deviceStatusStore: UserDevicePreferredStatusStore
    
    var defaultTitle: String {
        "\(AuthStore.shared.user?.name ?? "") " + NSLocalizedString("Created Room", comment: "")
    }
    
    lazy var currentRoomType = availableTypes.first! {
        didSet {
            guard currentRoomType != oldValue else { return }
            updateSelected()
        }
    }
    
    // MARK: - LifeCycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        deviceStatusStore = UserDevicePreferredStatusStore(userUUID: AuthStore.shared.user?.userUUID ?? "")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .formSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previewView.turnCamera(on: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateSelected()
        previewView.turnCamera(on: deviceView.cameraOn)
    }
    
    // MARK: - Private
    func setupViews() {
        addPresentCloseButton()
        addPresentTitle(localizeStrings("Start Now"))
        view.backgroundColor = .whiteBG
        view.addSubview(subjectTextField)
        view.addSubview(typesStackView)
        view.addSubview(previewView)
        
//        typesStackView.snp.makeConstraints { make in
//            make.left.right.equalToSuperview()
//            make.height.equalTo(66)
//            make.centerY.equalToSuperview().offset(-88)
//        }
        
        if isCompact() {
//            previewView.snp.makeConstraints { make in
//                make.top.equalTo(typesStackView.snp.bottom)
//                make.bottom.equalTo(deviceView.snp.top)
//                make.width.equalTo(previewView.snp.height).multipliedBy(16.0/9)
//                make.centerX.equalToSuperview()
//            }
//            deviceView.snp.makeConstraints { make in
//                make.left.right.equalToSuperview()
//                make.bottom.equalTo(createButton.snp.top).offset(-32)
//            }
//
//            createButton.snp.makeConstraints { make in
//                make.left.right.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)h
//                make.height.equalTo(40)
//            }
        } else {
            subjectTextField.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(80)
                make.height.equalTo(30 + 32)
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().inset(56)
            }
            
            typesStackView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().inset(96)
                make.height.equalTo(66)
                make.top.equalTo(subjectTextField.snp.bottom).offset(16)
            }
            typesStackView.arrangedSubviews.forEach { $0.snp.makeConstraints { make in
                make.width.equalTo(66)
            }}
            
            previewView.snp.makeConstraints { make in
                make.top.equalTo(typesStackView.snp.bottom).offset(16)
                make.width.equalTo(previewView.snp.height).multipliedBy(16.0/9)
                make.left.right.equalToSuperview().inset(40)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(64)
            }
            
            let createContainer = UIView()
            createContainer.addSubview(createButton)
            
            let bottomStack = UIStackView(arrangedSubviews: [deviceView, createContainer])
            bottomStack.axis = .horizontal
            bottomStack.spacing = 16
            view.addSubview(bottomStack)
            bottomStack.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(8)
                make.height.equalTo(48)
            }
            createContainer.snp.makeConstraints {
                $0.width.equalTo(88)
            }
            createButton.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
            }
            
            preferredContentSize = .init(width: 480, height: 506)
        }
    }
    
    func typeViewForType(_ type: ClassRoomType) -> UIButton {
        let button = UIButton(type: .custom)
        let image = UIImage(named: type.rawValue)
        button.setImage(image?.tintColor(.text), for: .normal)
        button.setImage(image?.tintColor(.brandColor), for: .selected)
        button.setTitle(type.rawValue, for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.verticalCenterImageAndTitleWith(2)
        button.addTarget(self, action: #selector(onClickType(_:)), for: .touchUpInside)
        return button
    }
    
    func updateSelected() {
        typeViews.forEach({ $0.isSelected = false })
        if let index = availableTypes.firstIndex(of: currentRoomType) {
            let selectedTypeView = typeViews[index]
            selectedTypeView.isSelected = true
        }
        
        subjectTextField.resignFirstResponder()
    }
    
    @objc func onClickType(_ sender: UIButton) {
        let newType = availableTypes[sender.tag]
        if currentRoomType != newType {
            currentRoomType = newType
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    @objc func onClickCreate(_ sender: UIButton) {
        let title: String
        let text = subjectTextField.text ?? ""
        title = text.isEmpty ? defaultTitle : text
        let startDate = Date()
        let createQuest = CreateRoomRequest(beginTime: startDate,
                          title: title,
                          type: currentRoomType)

        sender.isEnabled = false
        ApiProvider.shared.request(fromApi: createQuest)
            .flatMap { info -> Observable<(RoomPlayInfo, RoomBasicInfo)> in
                let playInfo = RoomPlayInfo.fetchByJoinWith(uuid: info.roomUUID, periodicUUID: info.periodicUUID)
                let roomInfo = RoomBasicInfo.fetchInfoBy(uuid: info.roomUUID, periodicUUID: nil)
                return Observable.zip(playInfo, roomInfo)
            }
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
    
    func joinRoom(withUUID UUID: String, completion: ((Result<ClassRoomViewController, Error>)->Void)?) {
        RoomPlayInfo.fetchByJoinWith(uuid: UUID, periodicUUID: nil) { playInfoResult in
            switch playInfoResult {
            case .success(let playInfo):
                RoomBasicInfo.fetchInfoBy(uuid: UUID, periodicUUID: nil) { result in
                    switch result {
                    case .success(let roomInfo):
                        let vc = ClassroomFactory.getClassRoomViewController(withPlayInfo: playInfo,
                                                                             detailInfo: roomInfo,
                                                                             deviceStatus: .init(mic: self.deviceView.micOn,
                                                                                                 camera: self.deviceView.cameraOn))
                        self.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: self.deviceView.cameraOn)
                        self.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: self.deviceView.micOn)
                        completion?(.success(vc))
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    // MARK: - Lazy
    lazy var subjectTextField: BottomLineTextfield = {
        let tf = BottomLineTextfield()
        tf.textColor = .strongText
        tf.font = .systemFont(ofSize: 20)
        tf.placeholder = localizeStrings("Room Subject Placeholder")
        tf.returnKeyType = .go
        tf.clearButtonMode = .whileEditing
        tf.placeholder = defaultTitle
        tf.textAlignment = .center
        tf.delegate = self
        return tf
    }()
    
    lazy var createButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton(type: .custom)
        btn.setTitle(localizeStrings("Start Class"), for: .normal)
        btn.addTarget(self, action: #selector(onClickCreate(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var typesStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: typeViews)
        view.axis = .horizontal
        view.distribution = .equalSpacing
        return view
    }()
    
    lazy var typeViews: [UIButton] = availableTypes.enumerated().map {
        let view = typeViewForType($0.element)
        view.tag = $0.offset
        return view
    }
    
    lazy var previewView = CameraPreviewView()
    
    lazy var deviceView: CameraMicToggleView = {
        let cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        let micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        let view = CameraMicToggleView(cameraOn: cameraOn, micOn: micOn)
        view.cameraOnUpdate = { [weak self] camera in
            self?.previewView.turnCamera(on: camera)
        }
        return view
    }()
}

extension CreateClassRoomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onClickCreate(createButton)
        return true
    }
}
