//
//  CreateClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class CreateClassRoomViewController: UIViewController {
    var availableTypes: [ClassRoomType] = [.bigClass, .smallClass, .oneToOne]

    let deviceStatusStore: UserDevicePreferredStatusStore

    var defaultTitle: String {
        "\(AuthStore.shared.user?.name ?? "") " + localizeStrings("Created Room")
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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateSelected()
        setupJoinRoomInputAccessView()
        simulatorUserDeviceStateSelect()
    }

    // MARK: - Private

    func setupViews() {
        addPresentCloseButton()
        addPresentTitle(localizeStrings("Start Now"))
        view.backgroundColor = .color(type: .background)

        let bottomStack = UIStackView(arrangedSubviews: [deviceView, createButton])
        view.addSubview(subjectTextField)
        view.addSubview(typesStackView)
        view.addSubview(previewView)
        view.addSubview(bottomStack)

        let guide0 = UILayoutGuide()
        let guide1 = UILayoutGuide()
        let guide2 = UILayoutGuide()
        view.addLayoutGuide(guide0)
        view.addLayoutGuide(guide1)
        view.addLayoutGuide(guide2)

        let margin: CGFloat = 16
        let baseHeight = CGFloat(66)

        guide0.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(56)
            make.height.greaterThanOrEqualTo(margin)
            make.height.lessThanOrEqualTo(margin * 2)
            make.height.equalTo(margin).priority(.low)
        }

        subjectTextField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(guide0.snp.bottom)
            make.width.equalTo(320)
            make.height.equalTo(baseHeight)
        }

        guide1.snp.makeConstraints { make in
            make.top.equalTo(subjectTextField.snp.bottom)
            make.height.greaterThanOrEqualTo(margin)
            make.height.equalTo(guide0)
        }

        typesStackView.arrangedSubviews.forEach { $0.snp.makeConstraints { make in
            make.width.equalTo(baseHeight)
        }}
        typesStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(guide1.snp.bottom)
            make.width.equalTo(subjectTextField)
            make.height.equalTo(baseHeight)
        }

        guide2.snp.makeConstraints { make in
            make.top.equalTo(typesStackView.snp.bottom)
            make.height.greaterThanOrEqualTo(margin)
            make.height.equalTo(guide1)
        }

        previewView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(guide2.snp.bottom)
            if traitCollection.hasCompact {
                make.height.equalTo(previewView.snp.width)
                make.width.lessThanOrEqualToSuperview().inset(margin / 2)
                make.width.equalToSuperview().inset(margin).priority(.medium)
            } else {
                make.width.equalTo(previewView.snp.height).multipliedBy(16.0 / 9)
                make.width.equalToSuperview().priority(.medium)
            }
        }

        bottomStack.axis = traitCollection.hasCompact ? .vertical : .horizontal
        bottomStack.backgroundColor = .color(type: .background)
        let bottomStackItemHeight: CGFloat = 44
        bottomStack.spacing = margin / 2
        bottomStack.distribution = .equalCentering
        bottomStack.alignment = .center
        if !traitCollection.hasCompact {
            bottomStack.spacing = margin
        }
        bottomStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(margin)
            if traitCollection.hasCompact {
                make.top.equalTo(previewView.snp.bottom)
                make.height.equalTo(bottomStackItemHeight * 2 + 8)
                make.left.right.equalToSuperview().inset(margin)
            } else {
                make.top.equalTo(previewView.snp.bottom).offset(margin)
                make.height.equalTo(bottomStackItemHeight)
                make.centerX.equalToSuperview()
            }
        }
        createButton.snp.makeConstraints { make in
            make.height.equalTo(bottomStackItemHeight)
            if traitCollection.hasCompact {
                make.width.equalToSuperview()
            }
        }

        preferredContentSize = .init(width: 480, height: 544)
    }

    func typeViewForType(_ type: ClassRoomType) -> UIButton {
        let button = SpringButton(type: .custom)
        let image = UIImage(named: type.rawValue)
        button.setTraitRelatedBlock { button in
            button.setImage(image?.tintColor(.color(type: .text, .weak).resolvedColor(with: button.traitCollection)), for: .normal)
            button.setImage(image?.tintColor(.color(type: .primary).resolvedColor(with: button.traitCollection)), for: .selected)
        }
        button.setTitle(localizeStrings(type.rawValue), for: .normal)
        button.setTitleColor(.color(type: .text), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.verticalCenterImageAndTitleWith(2)
        button.addTarget(self, action: #selector(onClickType(_:)), for: .touchUpInside)
        return button
    }

    func updateSelected() {
        typeViews.forEach { $0.isSelected = false }
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
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
        sender.isLoading = true
        ApiProvider.shared.request(fromApi: createQuest)
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, info in
                sender.isLoading = false
                let deviceStatus = DeviceState(mic: weakSelf.deviceView.micOn, camera: weakSelf.deviceView.cameraOn)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: deviceStatus.camera)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: deviceStatus.mic)
                ClassroomCoordinator.shared.enterClassroom(uuid: info.roomUUID,
                                                           periodUUID: info.periodicUUID,
                                                           basicInfo: nil,
                                                           sender: sender)
            }, onFailure: { weakSelf, error in
                sender.isLoading = false
                weakSelf.showAlertWith(message: error.localizedDescription)
            }, onDisposed: { _ in })
            .disposed(by: rx.disposeBag)
    }

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
        NotificationCenter.default.addObserver(self, selector: #selector(handle(keyboardShowNotification:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        roomInputAccessView.deviceStateView.delegate = deviceAutorizationHelper
        roomInputAccessView.deviceStateView.cameraOnUpdate = { [weak self] camera in
            self?.deviceView.set(cameraOn: camera)
            self?.previewView.turnCamera(on: camera)
        }
        roomInputAccessView.deviceStateView.micOnUpdate = { [weak self] micOn in
            self?.deviceView.set(micOn: micOn)
        }
        roomInputAccessView.joinButton.isHidden = true
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

    // MARK: - Lazy

    lazy var subjectTextField: BottomLineTextfield = {
        let tf = BottomLineTextfield()
        tf.textColor = .color(type: .text, .strong)
        tf.font = .systemFont(ofSize: 20)
        tf.placeholder = localizeStrings("Room Theme Placeholder")
        tf.returnKeyType = .go
        tf.clearButtonMode = .whileEditing
        tf.placeholder = defaultTitle
        tf.textAlignment = .center
        tf.delegate = self
        return tf
    }()

    lazy var roomInputAccessView = JoinRoomInputAccessView(cameraOn: deviceView.cameraOn,
                                                           micOn: deviceView.micOn,
                                                           enterTitle: "")

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

extension CreateClassRoomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onClickCreate(createButton)
        return true
    }
}
