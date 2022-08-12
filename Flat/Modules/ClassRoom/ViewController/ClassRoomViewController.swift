//
//  ClassRoomViewControllerV2.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Fastboard
import RxSwift
import RxCocoa

let classRoomLeavingNotificationName = Notification.Name("classRoomLeaving")

class ClassRoomViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return traitCollection.hasCompact ? .landscapeRight : .landscape
    }
    override var prefersStatusBarHidden: Bool { traitCollection.verticalSizeClass == .compact }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    let isOwner: Bool
    let ownerUUID: String
    let viewModel: ClassRoomViewModel
    
    // MARK: - Child Controllers
    let fastboardViewController: FastboardViewController
    let rtcListViewController: RtcViewController
    // TBD:
    let settingVC = ClassRoomSettingViewController(cameraOn: false, micOn: false, videoAreaOn: true, deviceUpdateEnable: false)
    let inviteViewController: UIViewController
    let userListViewController: ClassRoomUsersViewController
    var chatVC: ChatViewController?
    
    // MARK: - LifeCycle
    init(viewModel: ClassRoomViewModel,
         fastboardViewController: FastboardViewController,
         rtcListViewController: RtcViewController,
         userListViewController: ClassRoomUsersViewController,
         inviteViewController: UIViewController,
         isOwner: Bool,
         ownerUUID: String
    ) {
        self.viewModel = viewModel
        self.fastboardViewController = fastboardViewController
        self.rtcListViewController = rtcListViewController
        self.userListViewController = userListViewController
        self.inviteViewController = inviteViewController
        self.isOwner = isOwner
        self.ownerUUID = ownerUUID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        log(module: .alloc, level: .verbose, log: "\(self) init")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        updateLayout()
    }
    
    deinit {
        log(module: .alloc, level: .verbose, log: "\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        initRoomStatus()
    }
    
    // MARK: - Private
    func initRoomStatus() {
        // Only status is required
        // Other service can join later
        let result = viewModel.initialRoomStatus()
        
        result.0
            .do(
                onSuccess: { [weak self] in
                    self?.view.endFlatLoading()
                },
                onSubscribed: { [weak self] in
                    self?.view.startFlatLoading(showCancelDelay: 7, cancelCompletion: { [weak self] in
                        self?.stopSubModulesAndLeaveUIHierarchy()
                    })
                })
            .subscribe(
                with: self,
                onSuccess: { weakSelf, _ in
                    weakSelf.setupBinding() },
                onFailure: { weakSelf, error in
                    weakSelf.stopSubModules()
                    weakSelf.showAlertWith(message: NSLocalizedString("Init room error", comment: "") + error.localizedDescription) {
                        weakSelf.leaveUIHierarchy()
                    }}
            )
            .disposed(by: rx.disposeBag)
                
        result.1.subscribe(with: self, onNext: { weakSelf, error in
            weakSelf.showAlertWith(message: error.uiAlertString) {
                weakSelf.stopSubModulesAndLeaveUIHierarchy()
            }
        }).disposed(by: rx.disposeBag)
    }
    
    func setupBinding() {
        bindUsersList()
        bindRtc()
        bindWhiteboard()
        bindSetting()
        bindChat()
        bindTerminate()
        
        if isOwner {
            bindRecording()
        }
        
        // Only Teacher can stop the class,
        // So Teacher do not have to receive the alert
        if !isOwner {
            bindStoped()
            
        }
        
        viewModel.transformUserListInput(.init(stopInteractingTap: userListViewController.stopInteractingTap.asObservable(),
                                               disconnectTap: userListViewController.disconnectTap.asObservable(),
                                               tapSomeUserRaiseHand: userListViewController.raiseHandTap.asObservable(),
                                               tapSomeUserCamera: userListViewController.cameraTap.asObservable(),
                                               tapSomeUserMic: userListViewController.micTap.asObservable()))
            .drive()
            .disposed(by: rx.disposeBag)
        
        viewModel.transformRaiseHandClick(raiseHandButton.rx.tap)
            .drive()
            .disposed(by: rx.disposeBag)
        
        viewModel.raiseHandHide
            .asDriver(onErrorJustReturn: true)
            .drive(raiseHandButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        viewModel.isRaisingHand.asDriver(onErrorJustReturn: false)
            .drive(raiseHandButton.rx.isSelected)
            .disposed(by: rx.disposeBag)
        
        usersButton.rx.tap
            .subscribe(with: self, onNext: { weakSelf, source in
                weakSelf.popoverViewController(viewController: weakSelf.userListViewController, fromSource: weakSelf.usersButton)
            })
            .disposed(by: rx.disposeBag)
        
        inviteButton.rx.tap
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.popoverViewController(viewController: weakSelf.inviteViewController, fromSource: weakSelf.inviteButton)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindStoped() {
        viewModel.roomStoped
            .take(1)
            .subscribe(with: self, onNext: { weakSelf, _ in
                // Hide the error 'room ban'
                weakSelf.fastboardViewController.view.isHidden = true
                if let _ = weakSelf.presentedViewController { weakSelf.dismiss(animated: false, completion: nil) }
                weakSelf.showAlertWith(message: NSLocalizedString("Leaving room soon", comment: "")) {
                    weakSelf.stopSubModulesAndLeaveUIHierarchy()
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindRecording() {
        let output = viewModel.transformMoreTap(moreTap: moreButton.rx.sourceTap,
                                                topRecordingTap: recordingFlagView.endRecordingButton.rx.tap)
        output.isRecording
            .asDriver(onErrorJustReturn: false)
            .map { !($0)}
            .do(onNext: { [weak self] hide in
                guard let view = self?.recordingFlagView else { return }
                self?.toast(NSLocalizedString(hide ? "RecordingEndTips" : "RecordingStartTips", comment: ""),
                            timeInterval: 3)
                if !hide {
                    view.transform = .init(translationX: 0, y: -view.bounds.height)
                    UIView.animate(withDuration: 0.3) {
                        view.transform = .identity
                    }
                }
            })
            .drive(recordingFlagView.rx.isHidden)
            .disposed(by: rx.disposeBag)

        output.recordingDuration
            .map { i -> String in
                let min = Int(i) / 60
                let sec = Int(i) % 60
                return String(format: "%02d : %02d", min, sec)
            }
            .asDriver(onErrorJustReturn: "")
            .drive(recordingFlagView.durationLabel.rx.text)
            .disposed(by: rx.disposeBag)

        viewModel.members
            .distinctUntilChanged()
            .filter { [weak self] _ in
                return self?.viewModel.recordModel != nil
            }
            .flatMap { [unowned self] users in
                self.viewModel.recordModel!.updateLayout(joinedUsers: users)
            }
            .subscribe()
            .disposed(by: rx.disposeBag)
    }
    
    func bindTerminate() {
        NotificationCenter.default.rx.notification(UIApplication.willTerminateNotification)
            .subscribe(with: self, onNext: { weakSelf, _ in
                log(level: .info, log: "device terminate")
                weakSelf.viewModel.destroy()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindChat() {
        let initChatResult = viewModel.initChatChannel(
            .init(chatButtonTap: chatButton.rx.tap, chatControllerPresentedFetch: { [weak self] in
                guard let chatVC = self?.chatVC else { return .just(false) }
                return chatVC.rx.isPresented
        }))
        
        initChatResult
            .subscribe(with: self, onSuccess: { weakSelf, r in
                let chatViewModel = ChatViewModel(roomUUID: weakSelf.viewModel.roomUUID,
                                                  userNameProvider: r.userNameProvider,
                                                  rtm: r.channel,
                                                  notice: r.notice,
                                                  isBanned: r.isBanned,
                                                  isOwner: weakSelf.isOwner,
                                                  banMessagePublisher: r.banMessagePublisher)
                let vc = ChatViewController(viewModel: chatViewModel, userRtmId: weakSelf.viewModel.userUUID)
                weakSelf.chatVC = vc
                weakSelf.rightToolBar.forceUpdate(button: weakSelf.chatButton, visible: true)
                
                weakSelf.viewModel.transformBanClick(vc.banTextButton.rx.tap)
                    .subscribe()
                    .disposed(by: weakSelf.rx.disposeBag)
                
                r.chatButtonShowRedPoint
                    .drive(with: weakSelf, onNext: { weakSelf, show in
                        weakSelf.chatButton.updateBadgeHide(!show)
                    })
                    .disposed(by: weakSelf.rx.disposeBag)
            })
            .disposed(by: rx.disposeBag)
        
        chatButton.rx.tap
            .subscribe(with: self, onNext: { weakSelf, _ in
                guard let vc = weakSelf.chatVC else { return }
                weakSelf.popoverViewController(viewController: vc, fromSource: weakSelf.chatButton)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindUsersList() {
        userListViewController.users = viewModel.members
        
        viewModel.showUsersResPoint
            .subscribe(with: self, onNext: { weakSelf, show in
                weakSelf.usersButton.updateBadgeHide(!show)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindRtc() {
        rtcListViewController.bindUsers(viewModel.rtcUsers.asDriver(onErrorJustReturn: []), withTeacherRtmUUID: ownerUUID)
        rtcListViewController.bindLocalUser(viewModel.currentUser.asDriver(onErrorJustReturn: .empty))
        
        let inputSource = Observable.merge(
            rtcListViewController.localUserMicClick.map { ClassRoomViewModel.RtcInputType.mic },
            rtcListViewController.localUserCameraClick.map { ClassRoomViewModel.RtcInputType.camera },
            settingVC.cameraPublish.asObservable().map { ClassRoomViewModel.RtcInputType.camera },
            settingVC.micPublish.asObservable().map { ClassRoomViewModel.RtcInputType.mic }
        )
        viewModel.transformLocalRtcClick(inputSource)
            .drive()
            .disposed(by: rx.disposeBag)
        
        rtcListViewController.viewModel.rtc.screenShareJoinBehavior
            .skip(while: { !$0 })
            .subscribe(with: self, onNext: { weakSelf, isOn in
                weakSelf.toast(NSLocalizedString(isOn ? "ScreenShare-On" : "ScreenShare-Off", comment: ""))
                weakSelf.turnScreenShare(on: isOn)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindWhiteboard() {
        fastboardViewController.bind(observableWritable: viewModel.whiteboardEnable)
            .subscribe(with: self, onNext: { weakSelf, writable in
                weakSelf.rightToolBar.forceUpdate(button: weakSelf.cloudStorageButton, visible: writable)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindSetting() {
        settingButton.rx.controlEvent(.touchUpInside)
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.popoverViewController(viewController: weakSelf.settingVC,
                                               fromSource: weakSelf.settingButton)
            })
            .disposed(by: rx.disposeBag)
        
        settingVC.videoAreaPublish.asDriver(onErrorJustReturn: ())
                .drive(with: self, onNext: { weakSelf, _ in
                    let isOpen = !weakSelf.settingVC.videoAreaOn.value
                    weakSelf.settingVC.videoAreaOn.accept(isOpen)
                    weakSelf.updateLayout()
                    UIView.animate(withDuration: 0.3) {
                        weakSelf.rtcListViewController.view.alpha = isOpen ? 1 : 0
                        weakSelf.view.setNeedsLayout()
                        weakSelf.view.layoutIfNeeded()
                    }
                })
                .disposed(by: rx.disposeBag)
        
        viewModel.transformLogoutTap(settingVC.logoutButton.rx.sourceTap.map { [unowned self] _ in
            self.settingButton })
            .subscribe(with: self, onNext: { weakSelf, dismiss in
                if dismiss {
                    weakSelf.stopSubModulesAndLeaveUIHierarchy()
                }
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.currentUser.map { $0.status.isSpeak }
            .asDriver(onErrorJustReturn: false)
            .drive(settingVC.deviceUpdateEnable)
            .disposed(by: rx.disposeBag)
        
        viewModel.currentUser
            .map { $0.status.camera }
            .asDriver(onErrorJustReturn: false)
            .drive(settingVC.cameraOn)
            .disposed(by: rx.disposeBag)
        
        viewModel.currentUser
            .map { $0.status.mic }
            .asDriver(onErrorJustReturn: false)
            .drive(settingVC.micOn)
            .disposed(by: rx.disposeBag)
    }
    
    func turnScreenShare(on: Bool) {
        let canvas = rtcListViewController.viewModel.rtc.screenShareCanvas
        canvas.view = on ? screenShareView : nil
        rtcListViewController.viewModel.rtc.agoraKit.setupRemoteVideo(canvas)
        if on {
            if screenShareView.superview == nil {
                view.insertSubview(screenShareView, belowSubview: rightToolBar)
                screenShareView.snp.makeConstraints { make in
                    make.edges.equalTo(fastboardViewController.view)
                }
            }
        } else {
            if screenShareView.superview != nil {
                screenShareView.removeFromSuperview()
            }
        }
    }
    
    func setupViews() {
        view.backgroundColor = .whiteBG
        addChild(fastboardViewController)
        addChild(rtcListViewController)
        view.addSubview(rtcListViewController.view)
        view.addSubview(fastboardViewController.view)
        fastboardViewController.didMove(toParent: self)
        rtcListViewController.didMove(toParent: self)
        setupToolbar()

        // RecordView
        recordingFlagView.isHidden = true
        view.addSubview(recordingFlagView)
        recordingFlagView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            make.right.equalTo(fastboardViewController.view.snp.right)
            make.centerY.equalTo(fastboardViewController.view)
        }
        
        if !isOwner {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
    }
    
    func stopSubModules() {
        viewModel.destroy()
        fastboardViewController.leave()
        rtcListViewController.viewModel.rtc
            .leave()
            .subscribe()
            .disposed(by: rx.disposeBag)
    }
    func leaveUIHierarchy() {
        if let presenting = presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    func stopSubModulesAndLeaveUIHierarchy() {
        stopSubModules()
        leaveUIHierarchy()
    }
    
    // MARK: - Layout
    let classRoomLayout = ClassRoomLayout()
    func updateLayout() {
        let safeInset = UIEdgeInsets(top: 0, left: view.safeAreaInsets.left, bottom: 0, right: 0)
        var contentSize = view.bounds.inset(by: safeInset).size
        // Height should be greater than width, for sometimes, user enter with portrait orientation
        if contentSize.height > contentSize.width {
            contentSize = .init(width: contentSize.height, height: contentSize.width)
        }
        let layoutOutput = classRoomLayout.update(rtcHide: !settingVC.videoAreaOn.value, contentSize: contentSize)
        let x = layoutOutput.inset.left + safeInset.left
        let y = layoutOutput.inset.top + safeInset.top
        rtcListViewController.preferredMargin = classRoomLayout.rtcMargin
                
        switch layoutOutput.rtcDirection {
        case .top:
            if layoutOutput.rtcSize.height == 0 {
                fastboardViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(x)
                    make.top.equalTo(y)
                    make.size.equalTo(layoutOutput.whiteboardSize)
                }
            } else {
                rtcListViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(x)
                    make.top.equalTo(y)
                    make.size.equalTo(layoutOutput.rtcSize)
                }
                fastboardViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(rtcListViewController.view)
                    make.top.equalTo(rtcListViewController.view.snp.bottom)
                    make.size.equalTo(layoutOutput.whiteboardSize)
                }
            }
        case .right:
            fastboardViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(x)
                make.top.equalTo(y)
                make.size.equalTo(layoutOutput.whiteboardSize)
            }
            rtcListViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(fastboardViewController.view.snp.right)
                make.top.equalTo(fastboardViewController.view)
                make.size.equalTo(layoutOutput.rtcSize)
            }
        }
    }
    
    // MARK: - Lazy
    lazy var settingButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_setting")!
        return button
    }()
    
    lazy var moreButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_more")!
        return button
    }()

    lazy var raiseHandButton: RaiseHandButton = {
        let button = RaiseHandButton(type: .custom)
        return button
    }()

    lazy var chatButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "chat")!
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()
    
    lazy var usersButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "users")!
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()

    @objc func onClickStorage(_ sender: UIButton) {
        popoverViewController(viewController: cloudStorageListViewController, fromSource: sender)
    }
    
    lazy var cloudStorageListViewController: CloudStorageInClassViewController = {
        let vc = CloudStorageInClassViewController()
        vc.fileContentSelectedHandler = { [weak self] fileContent in
            guard let self = self else { return }
            switch fileContent {
            case .image(url: let url, image: let image):
                self.fastboardViewController.fastRoom.insertImg(url, imageSize: image.size)
            case .media(url: let url, title: let title):
                self.fastboardViewController.fastRoom.insertMedia(url, title: title, completionHandler: nil)
            case .multiPages(pages: let pages, title: let title):
                self.fastboardViewController.fastRoom.insertStaticDocument(pages, title: title, completionHandler: nil)
            case .pptx(pages: let pages, title: let title):
                self.fastboardViewController.fastRoom.insertPptx(pages, title: title, completionHandler: nil)
            case .projectorPptx(uuid: let uuid, prefix: let prefix, title: let title):
                self.fastboardViewController.fastRoom.insertPptx(uuid: uuid, url: prefix, title: title)
            }
            self.dismiss(animated: true, completion: nil)
        }
        return vc
    }()
     
    lazy var cloudStorageButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_cloud")!
        button.addTarget(self, action: #selector(onClickStorage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var inviteButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "invite")!
        return button
    }()

    
    lazy var rightToolBar: FastRoomControlBar = {
        if traitCollection.hasCompact {
            let bar = FastRoomControlBar(direction: .vertical,
                                         borderMask: [.layerMinXMinYCorner, .layerMinXMaxYCorner],
                                         views: [cloudStorageButton, usersButton, chatButton, inviteButton, settingButton])
            bar.forceUpdate(button: cloudStorageButton, visible: false)
            bar.forceUpdate(button: chatButton, visible: false)
            bar.narrowStyle = .none
            return bar
        } else {
            let bar = FastRoomControlBar(direction: .vertical,
                                         borderMask: [.layerMinXMinYCorner, .layerMinXMaxYCorner],
                                         views: [cloudStorageButton, chatButton, usersButton, chatButton, inviteButton, settingButton, moreButton])
            bar.forceUpdate(button: cloudStorageButton, visible: false)
            bar.forceUpdate(button: chatButton, visible: false)
            bar.forceUpdate(button: moreButton, visible: isOwner)
            return bar
        }
    }()

    lazy var recordingFlagView = RecordingFlagView(frame: .zero)
    
    lazy var screenShareView: UIView = {
        let view = UIView()
        view.backgroundColor = .whiteBG
        return view
    }()
}
