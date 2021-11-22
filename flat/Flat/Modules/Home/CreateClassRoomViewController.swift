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
    
    lazy var currentRoomType = availableTypes.first! {
        didSet {
            guard currentRoomType != oldValue else { return }
            updateSelected()
        }
    }
    
    var micOn: Bool {
        didSet {
            micButton.isSelected = micOn
        }
    }
    
    var cameraOn: Bool {
        didSet {
            cameraButton.isSelected = cameraOn
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateSelected()
    }
    
    // MARK: - Private
    func setupViews() {
        navigationItem.title = NSLocalizedString("Create Room", comment: "")
        view.backgroundColor = .white
        let topLabel = UILabel()
        topLabel.font = .systemFont(ofSize: 14)
        topLabel.textColor = .subText
        topLabel.text = NSLocalizedString("Room Subject", comment: "")
        view.addSubview(topLabel)
        view.addSubview(subjectTextField)
        
        let typeLabel = UILabel()
        typeLabel.font = .systemFont(ofSize: 14)
        typeLabel.textColor = .subText
        typeLabel.text = NSLocalizedString("Room Type", comment: "")
        view.addSubview(typeLabel)
        
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        let stackView = UIStackView(arrangedSubviews: typeViews)
        stackView.axis = .horizontal
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        let joinOptionsLabel = UILabel()
        joinOptionsLabel.font = .systemFont(ofSize: 14)
        joinOptionsLabel.textColor = .subText
        joinOptionsLabel.text = NSLocalizedString("Join Options", comment: "")
        view.addSubview(joinOptionsLabel)
        view.addSubview(cameraButton)
        view.addSubview(micButton)
        view.addSubview(createButton)
        
        let margin: CGFloat = 16
        topLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(margin)
        }
        subjectTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(46)
            make.height.equalTo(48)
        }
        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(subjectTextField.snp.bottom).offset(16)
            make.left.equalToSuperview().inset(margin)
        }
        
        stackView.spacing = margin
        stackView.distribution = .fillEqually
        let count = CGFloat(stackView.arrangedSubviews.count)
        let inset = (count + 1) / count  * margin
        typeViews.first?.snp.makeConstraints({ $0.width.equalTo(self.view).offset(-inset).multipliedBy(1.0 / 3.0)})
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(96)
        }
        scrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(140)
            make.height.equalTo(96)
        }
        
        joinOptionsLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(252)
        }
        
        cameraButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).inset(274)
        }
        
        micButton.snp.makeConstraints { make in
            make.left.equalTo(cameraButton.snp.right).offset(12)
            make.top.equalTo(cameraButton)
        }
        
        createButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(338)
            make.height.equalTo(32)
        }
    }
    
    func typeViewForType(_ type: ClassRoomType) -> ClassTypeCell {
        let view = ClassTypeCell()
        view.typeImageView.image = UIImage(named: type.rawValue)
        view.typeLaebl.text = NSLocalizedString(type.rawValue, comment: "")
        view.typeDescriptionLaebl.text = NSLocalizedString(type.rawValue + " Description", comment: "")
        view.addTarget(self, action: #selector(onClickType(_:)), for: .touchUpInside)
        return view
    }
    
    func updateSelected() {
        typeViews.forEach({ $0.isSelected = false })
        if let index = availableTypes.firstIndex(of: currentRoomType) {
            typeViews[index].isSelected = true
        }
    }
    
    @objc func onClickType(_ sender: ClassTypeCell) {
        currentRoomType = availableTypes[sender.tag]
    }
    
    @objc func onClickCamera(_ sender: UIButton) {
        cameraOn = !cameraOn
    }
    
    @objc func onClickMic(_ sender: UIButton) {
        micOn = !micOn
    }
    
    @objc func onClickCreate(_ sender: UIButton) {
        let title: String
        let text = subjectTextField.text ?? ""
        let defaultTitle = "\(AuthStore.shared.user?.name ?? "") " + NSLocalizedString("Created Room", comment: "")
        title = text.isEmpty ? defaultTitle : text
        let startDate = Date()
        let createQuest = CreateRoomRequest(beginTime: startDate,
                          title: title,
                          type: currentRoomType)
        
        sender.isEnabled = false
        ApiProvider.shared.request(fromApi: createQuest)
            .flatMap { info -> Observable<(RoomPlayInfo, RoomInfo)> in
                let playInfo = RoomPlayInfo.fetchByJoinWith(uuid: info.roomUUID)
                let roomInfo = RoomInfo.fetchInfoBy(uuid: info.roomUUID)
                return Observable.zip(playInfo, roomInfo)
            }
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, tuple in
                sender.isEnabled = true
                let playInfo = tuple.0
                let roomInfo = tuple.1
                let deviceStatus = ClassRoomFactory.DeviceStatus(mic: weakSelf.micOn, camera: weakSelf.cameraOn)
                let vc = ClassRoomFactory.getClassRoomViewController(withPlayinfo: playInfo,
                                                                     detailInfo: roomInfo,
                                                                     deviceStatus: deviceStatus)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: deviceStatus.camera)
                weakSelf.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: deviceStatus.mic)
                
                if let split = weakSelf.splitViewController {
                    let detailVC = RoomDetailViewControllerFactory.getRoomDetail(withInfo: roomInfo, roomUUID: playInfo.roomUUID)
                    split.showDetailViewController(BaseNavigationViewController(rootViewController: detailVC), sender: nil)
                    split.present(vc, animated: true, completion: nil)
                } else {
                    let navi = self.navigationController
                    navi?.popViewController(animated: false)
                    navi?.pushViewController(vc, animated: true)
                }
            }, onFailure: { weakSelf, error in
                sender.isEnabled = true
                weakSelf.showAlertWith(message: error.localizedDescription)
            }, onDisposed: { _ in
                return
            })
            .disposed(by: rx.disposeBag)
    }
    
    func joinRoom(withUUID UUID: String, completion: ((Result<ClassRoomViewController, Error>)->Void)?) {
        RoomPlayInfo.fetchByJoinWith(uuid: UUID) { playInfoResult in
            switch playInfoResult {
            case .success(let playInfo):
                RoomInfo.fetchInfoBy(uuid: UUID) { result in
                    switch result {
                    case .success(let roomInfo):
                        let vc = ClassRoomFactory.getClassRoomViewController(withPlayinfo: playInfo,
                                                                             detailInfo: roomInfo,
                                                                             deviceStatus: .init(mic: self.micOn,
                                                                                                 camera: self.cameraOn))
                        self.deviceStatusStore.updateDevicePreferredStatus(forType: .camera, value: self.cameraOn)
                        self.deviceStatusStore.updateDevicePreferredStatus(forType: .mic, value: self.micOn)
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
    lazy var subjectTextField: UITextField = {
        let tf = UITextField()
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.layer.borderWidth = 1 / UIScreen.main.scale
        tf.layer.cornerRadius = 4
        tf.clipsToBounds = true
        tf.textColor = .text
        tf.font = .systemFont(ofSize: 14)
        tf.placeholder = NSLocalizedString("Room Subject Placeholder", comment: "")
        tf.leftView = .init(frame: .init(origin: .zero, size: .init(width: 10, height: 20)))
        tf.leftViewMode = .always
        return tf
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
    
    lazy var createButton: FlatGeneralButton = {
        let btn = FlatGeneralButton(type: .custom)
        btn.setTitle(NSLocalizedString("Create", comment: ""), for: .normal)
        btn.addTarget(self, action: #selector(onClickCreate(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var typeViews: [ClassTypeCell] = availableTypes.enumerated().map {
        let view = typeViewForType($0.element)
        view.tag = $0.offset
        return view
    }
}
