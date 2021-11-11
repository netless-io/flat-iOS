//
//  ClassRoomViewController1.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/8.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift

class ClassRoomViewController1: UIViewController {
    let viewModel: ClassRoomViewModel
    
    var isTeacher:  Bool {
        viewModel.classRoom.isTeacher
    }

    let whiteBoardViewController: WhiteboardViewController
    let rtcViewController: RtcViewController
    let usersViewController: ClassRoomUsersViewController
    let inviteViewController: InviteViewController
    
    init(rtmData: (token: String, channelId: String),
         whiteboardData: (uuid: String, token: String),
         rtcData: (channelId: String, token: String, uid: UInt),
         roomUUID: String,
         roomType: ClassRoomType,
         status: RoomStartStatus,
         roomOwnerRtmUUID: String,
         initUser: RoomUser,
         roomTitle: String,
         beginTime: Date,
         roomNumber: String) {
        whiteBoardViewController = .init(uuid: whiteboardData.uuid,
                                         token: whiteboardData.token,
                                         userName: initUser.name)
        rtcViewController = RtcViewController(token: rtcData.token,
                                              channelId: rtcData.channelId,
                                              rtcUid: rtcData.uid)
        usersViewController = ClassRoomUsersViewController(userUUID: initUser.rtmUUID, roomOwnerRtmUUID: roomOwnerRtmUUID)
        inviteViewController = .init(roomTitle: roomTitle,
                                     roomTime: beginTime,
                                     roomNumber: roomNumber,
                                     roomUUID: rtmData.channelId,
                                     userName: initUser.name)
        
        let room = ClassRoom(userName: initUser.name,
                             userUUID: initUser.rtmUUID,
                             roomType: roomType,
                             messageBan: true,
                             status: status,
                             mode: .lecture,
                             users: [initUser],
                             roomOwnerRtmUUID: roomOwnerRtmUUID,
                             roomUUID: roomUUID)
        let rtm = ClassRoomRtm(rtmToken: rtmData.token,
                               userUID: initUser.rtmUUID,
                               roomUUID: rtmData.channelId)
        viewModel = .init(classRoom: room, rtm: rtm)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        
        rtcViewController.delegate = self
        
        usersViewController.dismissHandler = { [weak self] in
            self?.usersButton.isSelected = false
        }
        usersViewController.delegate = self
        
        inviteViewController.dismissHandler = { [weak self] in
            self?.inviteButton.isSelected = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        let joinWhiteboard = whiteBoardViewController.viewModel.joinRoom()
        let joinRtm = viewModel.join()
        let join = Observable.of(joinWhiteboard, joinRtm)
            .merge()
        join
            .subscribe (onError: { [weak self] error in
                self?.leaveWithAlertMessage(error.localizedDescription)
            }, onCompleted: { [weak self] in
                // Disable whiteboard before join success
                self?.whiteBoardViewController.viewModel.room.setWritable(false, completionHandler: nil)
                self?.whiteBoardViewController.toolStackView.isHidden = true
                self?.bindOthers()
            })
            .disposed(by: rx.disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Action
    @objc func onClickSetting(_ sender: UIButton) {
        sender.isSelected = true
        settingViewController.videoAreaOn = !rtcViewController.view.isHidden
        popoverViewController(viewController: settingViewController, fromSource: sender)
    }
    
    @objc func onClickChat(_ sender: UIButton) {
        sender.isSelected = true
        popoverViewController(viewController: chatViewController, fromSource: sender)
        chatViewController.updateBanTextButtonEnable(isTeacher)
    }
    
    @objc func onClickInvite(_ sender: UIButton) {
        sender.isSelected = true
        popoverViewController(viewController: inviteViewController, fromSource: sender)
    }
    
    @objc func onClickUsers(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        popoverViewController(viewController: usersViewController,
                              fromSource: sender)
    }
    
    // MARK: - Private
    func bindOthers() {
        // History
        viewModel.requestHistory().subscribe { [weak self] list in
            self?.chatViewController.messages.append(contentsOf: list)
        } onFailure: { _ in
            return
        } onDisposed: {
            return
        }
        .disposed(by: rx.disposeBag)
        
        // Request room status
        viewModel.requestRoomStatus().subscribe { [weak self] in
            self?.setupToolbar()
            self?.bindAfterStatusStable()
            self?.rtcViewController.joinChannel()
        } onError: { [weak self] error in
            self?.leaveWithAlertMessage(error.localizedDescription)
        }
        .disposed(by: rx.disposeBag)
    }
    
    func bindAfterStatusStable() {
        viewModel.erroSignal
            .asSignal()
            .emit(onNext: { [weak self] error in
                self?.leaveWithAlertMessage(error?.localizedDescription)
            })
            .disposed(by: rx.disposeBag)
        
        let isChatRoomPresent = Observable<Bool>.create { [weak self] ob in
            guard let self = self else {
                return Disposables.create()
            }
            if self.chatViewController.isBeingPresented {
                ob.onNext(true)
            } else if self.chatViewController.presentingViewController != nil {
                ob.onNext(true)
            } else {
                ob.onNext(false)
            }
            return Disposables.create()
        }
        
        let isUserRoomPresent = Observable<Bool>.create { [weak self] ob in
            guard let self = self else {
                return Disposables.create()
            }
            if self.usersViewController.isBeingPresented {
                ob.onNext(true)
            } else if self.usersViewController.presentingViewController != nil {
                ob.onNext(true)
            } else {
                ob.onNext(false)
            }
            return Disposables.create()
        }
        
        // Users button badge
        usersButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.usersButton.updateBadgeHide(true)
            })
            .disposed(by: rx.disposeBag)
        
        Observable.combineLatest(isUserRoomPresent, viewModel.unprocessUserSignal.asSignal().asObservable())
            .subscribe(onNext: { [weak self] present, unprocess in
                if present {
                    self?.usersButton.updateBadgeHide(false)
                } else {
                    self?.usersButton.updateBadgeHide(!unprocess)
                }
            })
            .disposed(by: rx.disposeBag)
        
        // Chat button badge
        chatButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.chatButton.updateBadgeHide(true)
            })
            .disposed(by: rx.disposeBag)
        
        // Chat button badge
        Observable.combineLatest(isChatRoomPresent, viewModel.receiveMessageSignal)
            .subscribe(onNext: { [weak self] present, _ in
                self?.chatButton.updateBadgeHide(present)
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.receiveMessageSignal
            .asSignal()
            .emit(onNext: { [weak self] message in
                self?.chatViewController.messages.append(message)
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.classRoom.users.bind { [weak self] users in
            guard let self = self else { return }
            let selfUID = self.viewModel.classRoom.userUUID
            let selfStatus = users.first(where: { $0.rtmUUID == selfUID })!.status
            self.settingViewController.micOn = selfStatus.mic
            self.settingViewController.cameraOn = selfStatus.camera
            
            self.usersViewController.users = users
            
            let roomOwnerRtmUUID = self.viewModel.classRoom.roomOwnerRtmUUID
            let containsTeach = users.contains(where: { $0.rtmUUID == roomOwnerRtmUUID
            })
            self.rtcViewController.shouldShowNoTeach = !containsTeach
            
            switch self.viewModel.classRoom.roomType.rtcStrategy {
            case .all:
                self.rtcViewController.users = users
            case .teacherOnly:
                self.rtcViewController.users = users.filter({
                    $0.rtmUUID == roomOwnerRtmUUID ||
                    $0.status.isSpeak
                })
            }
        }.disposed(by: rx.disposeBag)

        viewModel.cachedUserName.bind { [weak self] _ in
            self?.chatViewController.tableView.reloadData()
        }.disposed(by: rx.disposeBag)
        
        // Raising Hand
        viewModel.classRoom.users
            .map { [weak self] _ in
                (self?.viewModel.classRoom.userStatus.isRaisingHand) ?? false
            }
            .distinctUntilChanged()
            .bind(to: raiseHandButton.rx.isSelected)
            .disposed(by: rx.disposeBag)
        
        // Append notice
        viewModel.classRoom.messageBan
            .skip(1)
            .subscribe(onNext: { [weak self] ban in
                self?.chatViewController.messages.append(.notice(ban ? "已禁言" : "已解除禁言"))
            })
            .disposed(by: rx.disposeBag)
        
        // Sync ChatRoom
        viewModel.classRoom.messageBan
            .subscribe { [weak self] ban in
                // TODO: process in viewModel
                if self?.isTeacher == true {
                    self?.chatViewController.isMessageBaned = false
                } else {
                    self?.chatViewController.isMessageBaned = ban
                }
                self?.chatViewController.isInMessageBan = ban
            } onError: { _ in
                return
            } onCompleted: {
                return
            } onDisposed: {
                return
            }.disposed(by: rx.disposeBag)
        
        let userUUID = viewModel.classRoom.userUUID
        let isTeacher = Single<Bool>.create {
            $0(.success(self.isTeacher))
            return Disposables.create()
        }.asObservable()
        let selfUser = viewModel.classRoom.users.compactMap {
            return $0.first(where: { $0.rtmUUID == userUUID })
        }
        
        let isHandHide = Observable.combineLatest(selfUser, viewModel.classRoom.mode, isTeacher)
            .map { [weak self] user, mode, isTeach-> Bool in
                guard let self = self else { return true }
                if isTeach { return true }
                switch self.viewModel.classRoom.roomType.rtcStrategy {
                case .all:
                    switch mode {
                    case .lecture:
                        if user.status.isSpeak { return true }
                        return false
                    case .interaction:
                        return true
                    default:
                        break
                    }
                case .teacherOnly:
                    return user.status.isSpeak
                }
                return true
            }
        
        isHandHide
            .bind(to: raiseHandButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        let isWhiteboardEnable = Observable.combineLatest(isTeacher, viewModel.classRoom.mode, selfUser)
            .map({ [weak self] isTeacher, mode, user -> Bool in
                guard let self = self else { return false }
                if isTeacher { return true }
                switch self.viewModel.classRoom.roomType.rtcStrategy {
                case .teacherOnly:
                    return user.status.isSpeak
                case .all:
                    switch mode {
                    case .lecture:
                        return user.status.isSpeak
                    case .interaction:
                        return true
                    default:
                        return false
                    }
                }
            })
        
        isWhiteboardEnable
            .map { !$0 }
            .bind(to: whiteBoardViewController.toolStackView.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        isWhiteboardEnable
            .subscribe(onNext: { [weak self] enable in
                self?.whiteBoardViewController.viewModel.room.setWritable(enable, completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)

        Observable.combineLatest(isTeacher, viewModel.classRoom.status)
            .filter({ teacher, status in
                return !teacher && status == .Stopped
            })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showAlertWith(title: "提示", message: "房间已结束，点击退出") {
                    self.leaveWithAlertMessage(nil)
                }
            })
            .disposed(by: rx.disposeBag)
        
        // Teacher
        Observable.combineLatest(isTeacher, viewModel.classRoom.status)
            .filter({ isTeacher, _ in
                return isTeacher
            })
            .subscribe(onNext: { [weak self] _, status in
                guard let self = self else { return }
                // Teacher tool bar
                self.teacherOperationStackView.arrangedSubviews.forEach({
                    $0.removeFromSuperview()
                    self.teacherOperationStackView.removeArrangedSubview($0)
                })
                switch status {
                case .Idle:
                    self.teacherOperationStackView.addArrangedSubview(self.startButton)
                case .Paused:
                    self.teacherOperationStackView.addArrangedSubview(self.resumeButton)
                    self.teacherOperationStackView.addArrangedSubview(self.endButton)
                case .Started:
                    self.teacherOperationStackView.addArrangedSubview(self.pauseButton)
                    self.teacherOperationStackView.addArrangedSubview(self.endButton)
                default:
                    break
                }
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.stopClasssAlert
            .asSignal()
            .emit(onNext: { [weak self] action in
                self?.showCheckAlert(title: "确认结束上课?", message: "一旦结束上课，所有用户退出房间，并且自动结束课程和录制（如有），不能继续直播") {
                    action()
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        view.backgroundColor = .init(hexString: "#F7F9FB")
        
        addChild(whiteBoardViewController)
        addChild(rtcViewController)
        
        let horizontalLine = UIView(frame: .zero)
        horizontalLine.backgroundColor = .popoverBorder
        
        let stackView = UIStackView(arrangedSubviews: [rtcViewController.view,
                                                       horizontalLine,
                                                       whiteBoardViewController.view
                                                       ])
        stackView.axis = .vertical
        stackView.distribution = .fill
        view.addSubview(stackView)
        
        whiteBoardViewController.didMove(toParent: self)
        rtcViewController.didMove(toParent: self)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        horizontalLine.snp.makeConstraints { make in
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        rtcViewController.view.snp.makeConstraints { make in
            make.height.equalTo(104)
        }
    }
    
    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            make.right.equalTo(whiteBoardViewController.view.snp.right)
            make.centerY.equalTo(whiteBoardViewController.view)
        }
        
        let seperateLine = UIView()
        seperateLine.backgroundColor = .borderColor
        view.addSubview(seperateLine)
        seperateLine.snp.makeConstraints { make in
            make.left.equalTo(whiteBoardViewController.view.snp.right)
            make.top.bottom.equalTo(whiteBoardViewController.view)
            make.width.equalTo(1)
        }
        
        if isTeacher {
            view.addSubview(teacherOperationStackView)
            teacherOperationStackView.snp.makeConstraints { make in
                make.top.equalTo(whiteBoardViewController.view).offset(10)
                make.centerX.equalTo(whiteBoardViewController.view)
            }
        } else {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
            raiseHandButton.isHidden = true
        }
    }
    
    func leaveWithAlertMessage(_ msg: String? = nil) {
        func disconnectServices() {
            whiteBoardViewController.viewModel.leave()
            rtcViewController.leave()
            viewModel.leave()
        }
        
        func leaveUIHierarchy() {
            if let presenting = presentingViewController {
                presenting.dismiss(animated: true, completion: nil)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
        
        if let msg = msg, !msg.isEmpty {
            showAlertWith(message: msg) {
                disconnectServices()
                leaveUIHierarchy()
            }
        } else {
            disconnectServices()
            leaveUIHierarchy()
        }
    }
    // MARK: - Lazy
    lazy var settingViewController: ClassRoomSettingViewController = {
        let vc = ClassRoomSettingViewController(cameraOn: false,
                                                micOn: false,
                                                videoAreaOn: !rtcViewController.view.isHidden)
        vc.dismissHandler = { [weak self] in
            self?.settingButton.isSelected = false
        }
        vc.delegate = self
        return vc
    }()

    
    lazy var chatViewController: ChatViewController = {
        let vc = ChatViewController()
        vc.userRtmId = viewModel.classRoom.userUUID
        vc.delegate = self
        vc.dismissHandler = { [weak self] in
            self?.chatButton.isSelected = false
        }
        return vc
    }()

    lazy var teacherOperationStackView: UIStackView = {
       let view = UIStackView(arrangedSubviews: [])
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.spacing = 10
        return view
    }()

    lazy var startButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitle(NSLocalizedString("Start Class", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.setTitleColor(.brandColor, for: .normal)
        btn.layer.cornerRadius = 10
        btn.layer.borderColor = UIColor.brandColor.cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        btn.clipsToBounds = true
        btn.addTarget(viewModel, action: #selector(viewModel.onClickStart), for: .touchUpInside)
        return btn
    }()

    lazy var pauseButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitle(NSLocalizedString("Pause Class", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.setTitleColor(.subText, for: .normal)
        btn.layer.cornerRadius = 10
        btn.layer.borderColor = UIColor.borderColor.cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        btn.clipsToBounds = true
        btn.addTarget(viewModel, action: #selector(viewModel.onClickPause), for: .touchUpInside)
        return btn
    }()

    lazy var resumeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitle(NSLocalizedString("Resume Class", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.setTitleColor(.brandColor, for: .normal)
        btn.layer.cornerRadius = 10
        btn.layer.borderColor = UIColor.brandColor.cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        btn.clipsToBounds = true
        btn.addTarget(viewModel, action: #selector(viewModel.onClickResume), for: .touchUpInside)
        return btn
    }()

    lazy var endButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(NSLocalizedString("Stop Class", comment: ""), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        btn.setTitleColor(.init(hexString: "#F45454"), for: .normal)
        btn.layer.cornerRadius = 10
        btn.layer.borderColor = UIColor.init(hexString: "#F45454").cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        btn.clipsToBounds = true
        btn.addTarget(viewModel, action: #selector(viewModel.onClickStop), for: .touchUpInside)
        return btn
    }()

    lazy var settingButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "classroom_setting")!)
        button.addTarget(self, action: #selector(onClickSetting(_:)), for: .touchUpInside)
        return button
    }()

    lazy var raiseHandButton: RaiseHandButton = {
        let button = RaiseHandButton(type: .custom)
        button.addTarget(viewModel, action: #selector(viewModel.onClickRaiseHand), for: .touchUpInside)
        return button
    }()

    lazy var chatButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "chat")!)
        button.addTarget(self, action: #selector(onClickChat(_:)), for: .touchUpInside)
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()
    
    lazy var usersButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "users")!)
        button.addTarget(self, action: #selector(onClickUsers(_:)), for: .touchUpInside)
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()

    lazy var inviteButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "invite")!)
        button.addTarget(self, action: #selector(onClickInvite(_:)), for: .touchUpInside)
        return button
    }()

    lazy var rightToolBar: RoomControlBar = {
        let bar = RoomControlBar(direction: .vertical,
                                 borderMask: [.layerMinXMinYCorner, .layerMinXMaxYCorner],
                                 buttons: isTeacher ? [chatButton, usersButton, inviteButton, settingButton] : [chatButton, usersButton, inviteButton, settingButton],
                                 narrowStyle: .narrowMoreThan(count: 1))
        return bar
    }()
}

// MARK: - Settings
extension ClassRoomViewController1: ClassRoomSettingViewControllerDelegate {
    func classRoomSettingViewControllerDidClickLeave(_ controller: ClassRoomSettingViewController) {
        let status = viewModel.classRoom.status.value
        if status == .Idle {
            leaveWithAlertMessage(nil)
            return
        }
        if isTeacher {
            let vc = UIAlertController(title: "关闭选项", message: "课堂正在继续，你是暂时离开还是结束上课？", preferredStyle: .actionSheet)
            vc.addAction(.init(title: "取消", style: .cancel, handler: nil))
            vc.addAction(.init(title: "暂时离开", style: .default, handler: { _ in
                self.leaveWithAlertMessage(nil)
            }))
            vc.addAction(.init(title: "结束上课", style: .destructive, handler: { _ in
                self.viewModel.endClass()
                self.leaveWithAlertMessage(nil)
            }))
            dismiss(animated: false, completion: nil)
            popoverViewController(viewController: vc, fromSource: rightToolBar)
        } else {
            dismiss(animated: false, completion: nil)
            showCheckAlert(title: "确认退出房间?", message: "课堂正在继续，确定退出房间") {
                self.leaveWithAlertMessage(nil)
            }
        }
    }
    
    func classRoomSettingViewControllerDidUpdateControl(_ vc: ClassRoomSettingViewController, type: ClassRoomSettingViewController.ControlType, isOn: Bool) {
        switch type {
        case .videoArea:
            UIView.animate(withDuration: 0.3) {
                self.rtcViewController.view.isHidden = !self.rtcViewController.view.isHidden
            }
        case .mic:
            viewModel.onClickUserMic()
        case .camera:
            viewModel.onClickUserCamera()
        }
    }
}

// MARK: - Chat
extension ClassRoomViewController1: ChatViewControllerDelegate {
    func chatViewControllerDidClickBanMessage(_ controller: ChatViewController) {
        viewModel.onClickBanMessage()
    }
    
    func chatViewControllerDidSendMessage(_ controller: ChatViewController, message: String) {
        viewModel.sendMessage(message)
    }
    
    func chatViewControllerNeedNickNameForUserId(_ controller: ChatViewController, userId: String) -> String? {
        viewModel.requestNickNameFor(userId: userId)
    }
}

// MARK: - Rtc
extension ClassRoomViewController1: RtcViewControllerDelegate {
    func rtcViewControllerDidClickMic(_ controller: RtcViewController, forUser user: RoomUser) {
        viewModel.onClickUserMic(userRtmUUID: user.rtmUUID)
    }
    
    func rtcViewControllerDidClickCamera(_ controller: RtcViewController, forUser user: RoomUser) {
        viewModel.onClickUserCamera(userRtmUUID: user.rtmUUID)
    }
    
    func rtcViewControllerDidMeetError(_ controller: RtcViewController, error: Error) {
        // TODO: Update Rtc with error
    }
}

// MARK: - Users List
extension ClassRoomViewController1: ClassRoomUsersViewControllerDelegate {
    func classRoomUsersViewControllerDidClickStopInteracting(_ vc: ClassRoomUsersViewController) {
        viewModel.onClickStopInteracting()
    }
    
    func classRoomUsersViewControllerDidClickRaiseHand(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        viewModel.onClickRaisedHandFor(user: user)
    }
    
    func classRoomUsersViewControllerDidClickDisConnect(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        viewModel.onClickDisconnect(user: user)
    }
    
    func classRoomUsersViewControllerDidClickMic(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        viewModel.onClickUserMic(userRtmUUID: user.rtmUUID)
    }
    
    func classRoomUsersViewControllerDidClickCamera(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        viewModel.onClickUserCamera(userRtmUUID: user.rtmUUID)
    }
}
