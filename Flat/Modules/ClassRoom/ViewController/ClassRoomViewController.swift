//
//  ClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/10.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift
import RxRelay
import RxCocoa
import Fastboard

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
    
    let layout = ClassRoomLayout()
    
    var viewModel: ClassRoomViewModel!
    
    var chatVCDisposeBag = RxSwift.DisposeBag()
    
    // MARK: - Child Controllers
    let fastboardViewController: FastboardViewController
    let rtcViewController: RtcViewController
    let settingVC = ClassRoomSettingViewController(cameraOn: false, micOn: false, videoAreaOn: true)
    let inviteViewController: () -> UIViewController
    let usersViewController: ClassRoomUsersViewController
    var chatVC: ChatViewController?
    
    // MARK: - LifeCycle
    init(fastboardViewController: FastboardViewController,
         rtcViewController: RtcViewController,
         classRoomState: ClassRoomState,
         rtm: ClassRoomRtm,
         chatChannelId: String,
         commandChannelId: String,
         roomOwnerRtmUUID: String,
         roomTitle: String,
         beginTime: Date,
         endTime: Date,
         roomNumber: String,
         roomUUID: String,
         isTeacher: Bool,
         userUUID: String,
         userName: String) {
        self.usersViewController = ClassRoomUsersViewController(userUUID: userUUID,
                                                                roomOwnerRtmUUID: roomOwnerRtmUUID)
        self.inviteViewController = {
            ShareManager.createShareActivityViewController(roomUUID: roomUUID,
                                                                                   beginTime: beginTime,
                                                                                   title: roomTitle,
                                                                                   roomNumber: roomNumber)
        }
        self.rtcViewController = rtcViewController
        self.fastboardViewController = fastboardViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        
        let alertProvider = DefaultAlertProvider(root: self)
        
        self.viewModel = .init(isTeacher: isTeacher,
                               chatChannelId: chatChannelId,
                               commandChannelId: commandChannelId,
                               userUUID: userUUID,
                               state: classRoomState,
                               rtm: rtm,
                               alertProvider: alertProvider)
    }
    
    deinit {
        print(self, "deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        bindGeneral()
        bindUsers()
        bindRtc()
        bindUserList()
        bindSetting()
        bindInteracting()
        bindRecording()
        postingClassStatusUpdateNotification()
        updateLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        updateLayout()
    }
    
    func updateLayout() {
        let safeInset = UIEdgeInsets(top: 0, left: view.safeAreaInsets.left, bottom: 0, right: 0)
        var contentSize = view.bounds.inset(by: safeInset).size
        // Height should be greater than width, for sometimes, user enter with portrait orientation
        if contentSize.height > contentSize.width {
            contentSize = .init(width: contentSize.height, height: contentSize.width)
        }
        let layoutOutput = layout.update(rtcHide: !settingVC.videoAreaOn.value, contentSize: contentSize)
        let x = layoutOutput.inset.left + safeInset.left
        let y = layoutOutput.inset.top + safeInset.top
        rtcViewController.preferredMargin = layout.rtcMargin
                
        switch layoutOutput.rtcDirection {
        case .top:
            if layoutOutput.rtcSize.height == 0 {
                fastboardViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(x)
                    make.top.equalTo(y)
                    make.size.equalTo(layoutOutput.whiteboardSize)
                }
            } else {
                rtcViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(x)
                    make.top.equalTo(y)
                    make.size.equalTo(layoutOutput.rtcSize)
                }
                fastboardViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(rtcViewController.view)
                    make.top.equalTo(rtcViewController.view.snp.bottom)
                    make.size.equalTo(layoutOutput.whiteboardSize)
                }
            }
        case .right:
            fastboardViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(x)
                make.top.equalTo(y)
                make.size.equalTo(layoutOutput.whiteboardSize)
            }
            rtcViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(fastboardViewController.view.snp.right)
                make.top.equalTo(fastboardViewController.view)
                make.size.equalTo(layoutOutput.rtcSize)
            }
        }
    }
    
    // MARK: - Private Setup
    func setupViews() {
        view.backgroundColor = .whiteBG
        addChild(fastboardViewController)
        addChild(rtcViewController)
        view.addSubview(rtcViewController.view)
        view.addSubview(fastboardViewController.view)
        fastboardViewController.didMove(toParent: self)
        rtcViewController.didMove(toParent: self)
        setupToolbar()
        
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
        
        if !viewModel.isTeacher {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
    }
    
    func setupChatViewController() {
        let banNotice = viewModel.state.messageBan
            .skip(1)
            .map { return $0 ? "已禁言" : "已解除禁言" }

        // Is chat been banning, not include user self
        let banning = viewModel.state.messageBan.asDriver()

        // Is user banned
        let baned = viewModel.state.messageBan.map { [ weak self] in
            (self?.viewModel.isTeacher ?? false) ? false : $0
        }.asDriver(onErrorJustReturn: true)

        let showRedPoint = viewModel.rtm.joinChannelId(viewModel.chatChannelId)
            // TODO: onError
            .do(onSuccess: { [weak self] handler in
                guard let self = self else { return }
                let pairs = self.viewModel.state.users.value.map {
                    ($0.rtmUUID, $0.name)
                }
                let existUserDic = [String: String](uniqueKeysWithValues: pairs)
                let viewModel = ChatViewModel(roomUUID: self.viewModel.state.roomUUID,
                                              cachedUserName: existUserDic,
                                              rtm: handler,
                                              notice: banNotice,
                                              banning: banning,
                                              banned: baned)
                let vc = ChatViewController(viewModel: viewModel, userRtmId: self.viewModel.userUUID)
                self.viewModel.tranform(banTap: vc.banTextButton.rx.tap
                                            .asDriver())
                    .drive()
                    .disposed(by: self.rx.disposeBag)
                self.chatVC = vc
                self.rightToolBar.forceUpdate(button: self.chatButton, visible: true)
            })
            .asObservable()
            .flatMap { handler -> Observable<Void> in
                return handler.newMessagePublish.asObservable().map { _ -> Void in return () }
            }.flatMap { [weak self] _ -> Observable<Bool> in
                guard let vc = self?.chatVC else {
                    return Observable.just(false)
                }
                return vc.rx.isPresented.asObservable()
            }.map {
                !$0
            }.asDriver(onErrorJustReturn: false)

        let tapChatShouldShowRed = chatButton.rx.tap.asDriver().map { _ -> Bool in return false }

        Driver.of(tapChatShouldShowRed, showRedPoint).merge()
            .drive(onNext: { [weak self] show in
                self?.chatButton.updateBadgeHide(!show)
            })
            .disposed(by: chatVCDisposeBag)
    }
    
    // MARK: - Private
    func bindGeneral() {
        let input = ClassRoomViewModel.Input(trigger: .just(()))
        let output = viewModel.transform(input)
        
        output.initRoom
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] in
                self?.view.endFlatLoading()
            }, onSubscribed: { [weak self] in
                self?.view.startFlatLoading(showCancelDelay: 7, cancelCompletion: {
                    self?.stopSubModulesAndLeaveUIHierarchy()
                })
            })
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.rightToolBar.isHidden = false
                weakSelf.setupChatViewController()
            }, onError: { weakSelf, error in
                weakSelf.showAlertWith(message: NSLocalizedString("Init room error", comment: "") + error.localizedDescription) {
                    weakSelf.stopSubModulesAndLeaveUIHierarchy()
                }
            })
            .disposed(by: rx.disposeBag)
                
        output.memberLeft
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.roomStopped
            .drive(with: self, onNext: { weakSelf, _ in
                // Hide the error 'room ban'
                weakSelf.fastboardViewController.view.isHidden = true
                // Only Teacher can stop the class,
                // So Teacher do not have to receive the alert
                if !weakSelf.viewModel.isTeacher {
                    if let _ = weakSelf.presentedViewController { weakSelf.dismiss(animated: false, completion: nil) }
                    weakSelf.showAlertWith(message: NSLocalizedString("Leaving room soon", comment: "")) {
                        weakSelf.stopSubModulesAndLeaveUIHierarchy()
                    }
                }
            })
            .disposed(by: rx.disposeBag)
                
        output.roomError
                .asDriver(onErrorJustReturn: "unknown reason")
                .drive(with: self, onNext: { weakSelf, reason in
                    weakSelf.stopSubModules()
                    weakSelf.showAlertWith(message: reason) {
                        weakSelf.leaveUIHierarchy()
                    }
                })
                .disposed(by: rx.disposeBag)
        
        // Should show user red (when received raiseHand while user panel is not presenting)
        let hideUserRedPointWhenNewRaiseHand = output.newCommand.filter {
            if case .raiseHand(let raise) = $0, raise { return true }
            return false
        }.flatMap { [weak self] _ -> Observable<Bool> in
            guard let vc = self?.usersViewController else { return .just(false) }
            return vc.rx.isPresented.asObservable()
        }.asDriver(onErrorJustReturn: true)
        
        Driver.of(hideUserRedPointWhenNewRaiseHand,
                  usersButton.rx.tap.asDriver().map { _ -> Bool in true })
            .merge()
            .drive(onNext: { [weak self] hide in
                self?.usersButton.updateBadgeHide(hide)
            })
            .disposed(by: rx.disposeBag)
        
        // Bind user's device status to setting view
        viewModel.userSelf
            .distinctUntilChanged()
            .drive(with: self, onNext: { weakSelf, user in
                weakSelf.settingVC.cameraOn.accept(user.status.camera)
                weakSelf.settingVC.micOn.accept(user.status.mic)
            })
            .disposed(by: rx.disposeBag)
        
        // Some tap to pop
        chatButton.rx.tap.asDriver()
            .drive(with: self, onNext: { weakSelf, _ in
                guard let vc = weakSelf.chatVC else { return }
                weakSelf.popoverViewController(viewController: vc, fromSource: weakSelf.chatButton)
                vc.updateBanTextButtonEnable(weakSelf.viewModel.isTeacher)
            })
            .disposed(by: rx.disposeBag)
        
        inviteButton.rx.tap.asDriver()
            .drive(with: self, onNext: { weakSelf, _ in
                let vc = weakSelf.inviteViewController()
                weakSelf.popoverViewController(viewController: vc, fromSource: weakSelf.inviteButton)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func postingClassStatusUpdateNotification() {
        viewModel.state.startStatus
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                NotificationCenter.default.post(name: classStatusUpdateNotification,
                                                object: nil,
                                                userInfo: ["classRoomUUID": self.viewModel.state.roomUUID,
                                                           "status": status])
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindInteracting() {
        viewModel.transformRaiseHand(raiseHandButton.rx.tap.asDriver())
            .drive()
            .disposed(by: rx.disposeBag)
        
        // Raise Hand
        viewModel.raiseHandSelected
            .drive(raiseHandButton.rx.isSelected)
            .disposed(by: rx.disposeBag)
            
        viewModel.raiseHandHide
            .drive(raiseHandButton.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        fastboardViewController.isRoomJoined
            .asDriver()
            .flatMap { [weak self] _ -> Driver<Bool> in
                guard let self = self else { return .just(false) }
                return self.viewModel.isWhiteboardEnable
            }
            .drive(with: self, onNext: { weakSelf, enable in
                weakSelf.fastboardViewController.fastRoom.setAllPanel(hide: !enable)
                weakSelf.fastboardViewController.fastRoom.updateWritable(enable, completion: nil)
                weakSelf.rightToolBar.forceUpdate(button: weakSelf.cloudStorageButton, visible: enable)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindUserList() {
        viewModel.transformUserListInput(.init(stopInteractingTap: usersViewController.stopInteractingTap.asDriver(onErrorJustReturn: ()),
                                                         disconnectTap: usersViewController.disconnectTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserRaiseHand: usersViewController.raiseHandTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserCamera: usersViewController.cameraTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserMic: usersViewController.micTap.asDriver(onErrorJustReturn: .emtpy)))
            .drive()
            .disposed(by: rx.disposeBag)
    }
    
    func bindUsers() {
        usersButton.rx.tap.asDriver()
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.popoverViewController(viewController: weakSelf.usersViewController, fromSource: weakSelf.usersButton)
            })
            .disposed(by: rx.disposeBag)
        
        usersViewController.users  = viewModel.state.users.asObservable()
    }
    
    func bindSetting() {
        settingButton.rx.tap.asDriver()
            .do(onNext: { [weak self] in
                guard let self = self else { return }
                self.popoverViewController(viewController: self.settingVC, fromSource: self.settingButton)
            }).drive()
            .disposed(by: rx.disposeBag)
                
        settingVC.videoAreaPublish.asDriver(onErrorJustReturn: ())
                .drive(with: self, onNext: { weakSelf, _ in
                    let isOpen = !weakSelf.settingVC.videoAreaOn.value
                    weakSelf.settingVC.videoAreaOn.accept(isOpen)
                    weakSelf.updateLayout()
                    UIView.animate(withDuration: 0.3) {
                        weakSelf.rtcViewController.view.alpha = isOpen ? 1 : 0
                        weakSelf.view.setNeedsLayout()
                        weakSelf.view.layoutIfNeeded()
                    }
                })
                .disposed(by: rx.disposeBag)
        
        let output = viewModel.transformSetting(.init(
            leaveTap: settingVC.logoutButton.rx.sourceTap.map { [unowned self] _ in
                self.settingButton
            },
            cameraTap: settingVC.cameraPublish.asDriver(onErrorJustReturn: ()),
            micTap: settingVC.micPublish.asDriver(onErrorJustReturn: ())))
        
        output.deviceTask
            .drive()
            .disposed(by: rx.disposeBag)
        
        output.dismiss
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.stopSubModulesAndLeaveUIHierarchy()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindRtc() {
        let cameraTap = rtcViewController.localUserCameraClick.asDriver(onErrorJustReturn: ())
        let micTap = rtcViewController.localUserMicClick.asDriver(onErrorJustReturn: ())
        
        viewModel.transform(localUserCameraTap: cameraTap,
                            localUserMicTap: micTap)
            .drive()
            .disposed(by: rx.disposeBag)
        
        rtcViewController.bindLocalUser(viewModel.userSelf)
        
        rtcViewController.bindUsers(viewModel.rtcUsers, withTeacherRtmUUID: viewModel.state.roomOwnerRtmUUID)
        
        rtcViewController.viewModel.rtc.screenShareJoinBehavior
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .drive(with: self, onNext: { weakSelf, isOn in
                // If the room is not joined, it usually means user is still loading
                // Do not toast when loading
                if weakSelf.fastboardViewController.isRoomJoined.value {
                    weakSelf.toast(NSLocalizedString(isOn ? "ScreenShare-On" : "ScreenShare-Off", comment: ""))
                }
                weakSelf.turnScreenShare(on: isOn)
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

        viewModel.state.users
            .distinctUntilChanged()
            .filter { [weak self] _ in
                return self?.viewModel.recordModel != nil
            }
            .flatMap { [unowned self] _ in
                self.viewModel.recordModel!.updateLayout(roomState: self.viewModel.state)
            }
            .subscribe()
            .disposed(by: rx.disposeBag)
    }
    
    func stopSubModules() {
        fastboardViewController.leave()
        rtcViewController.viewModel.rtc.leave()
            .subscribe()
            .disposed(by: rx.disposeBag)
    }
    
    func leaveUIHierarchy() {
        let state = viewModel.state
        if let presenting = presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        NotificationCenter.default.post(name: classRoomLeavingNotificationName,
                                        object: nil,
                                        userInfo: ["state": state])
    }
    
    func stopSubModulesAndLeaveUIHierarchy() {
        stopSubModules()
        leaveUIHierarchy()
    }
    
    func turnScreenShare(on: Bool) {
        let canvas = rtcViewController.viewModel.rtc.screenShareCanvas
        canvas.view = on ? screenShareView : nil
        rtcViewController.viewModel.rtc.agoraKit.setupRemoteVideo(canvas)
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
            bar.forceUpdate(button: moreButton, visible: viewModel.isTeacher)
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
