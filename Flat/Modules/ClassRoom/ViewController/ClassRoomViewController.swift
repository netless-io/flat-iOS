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
    let whiteboardViewController: WhiteboardViewController
    let rtcViewController: RtcViewController
    let settingVC = ClassRoomSettingViewController(cameraOn: false, micOn: false, videoAreaOn: true)
    let inviteViewController: UIViewController
    let usersViewController: ClassRoomUsersViewController
    var chatVC: ChatViewController?
    
    // MARK: - LifeCycle
    init(whiteboardViewController: WhiteboardViewController,
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
        self.inviteViewController = ShareManager.createShareActivityViewController(roomUUID: roomUUID,
                                                                                   beginTime: beginTime,
                                                                                   title: roomTitle)
        self.rtcViewController = rtcViewController
        self.whiteboardViewController = whiteboardViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .flipHorizontal
        
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
        postingClassStatusUpdateNotification()
        updateLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }
    
    func updateLayout() {
        let safeInset = UIEdgeInsets.zero
        let contentSize = view.bounds.inset(by: safeInset).size
        let layoutOutput = layout.update(rtcHide: !settingVC.videoAreaOn.value, contentSize: contentSize)
        let x = layoutOutput.inset.left
        let y = layoutOutput.inset.top
        rtcViewController.preferredMargin = layout.rtcMargin
                
        switch layoutOutput.rtcDirection {
        case .top:
            if layoutOutput.rtcSize.height == 0 {
                whiteboardViewController.view.snp.remakeConstraints { make in
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
                whiteboardViewController.view.snp.remakeConstraints { make in
                    make.left.equalTo(rtcViewController.view)
                    make.top.equalTo(rtcViewController.view.snp.bottom)
                    make.size.equalTo(layoutOutput.whiteboardSize)
                }
            }
        case .right:
            whiteboardViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(x)
                make.top.equalTo(y)
                make.size.equalTo(layoutOutput.whiteboardSize)
            }
            rtcViewController.view.snp.remakeConstraints { make in
                make.left.equalTo(whiteboardViewController.view.snp.right)
                make.top.equalTo(whiteboardViewController.view)
                make.size.equalTo(layoutOutput.rtcSize)
            }
        }
    }
    
    // MARK: - Private Setup
    func setupViews() {
        view.backgroundColor = .commonBG
        addChild(whiteboardViewController)
        addChild(rtcViewController)
        view.addSubview(rtcViewController.view)
        view.addSubview(whiteboardViewController.view)
        whiteboardViewController.didMove(toParent: self)
        rtcViewController.didMove(toParent: self)
        setupToolbar()
    }
    
    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            make.right.equalTo(whiteboardViewController.view.snp.right)
            make.centerY.equalTo(whiteboardViewController.view)
        }
        
        if !viewModel.isTeacher {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
    }
    
    func destroyChatViewController() {
        print("destroy chatVC")
        chatVC?.dismiss(animated: false, completion: nil)
        chatButton.isHidden = false
        chatVC = nil
        chatVCDisposeBag = RxSwift.DisposeBag()
    }
    
    func setupChatViewController() {
        print("setup chatVC")
        chatButton.isHidden = true
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
                self.chatButton.isHidden = false
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
        let input = ClassRoomViewModel.Input(trigger: .just(()),
                                             enterBackground: UIApplication.rx.didEnterBackground.asDriver(),
                                             enterForeground: UIApplication.rx.willEnterForeground.asDriver())
        let output = viewModel.transform(input)
        
        output.initRoom
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] in
                self?.view.endFlatLoading()
            }, onSubscribed: { [weak self] in
                self?.view.startFlatLoading(showCancelDelay: 7, cancelCompletion: {
                    self?.leaveUIHierarchyAndStopSubModule()
                })
            })
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.rightToolBar.isHidden = false
                weakSelf.setupChatViewController()
            }, onError: { weakSelf, error in
                weakSelf.leaveUIHierarchyAndStopSubModule()
            })
            .disposed(by: rx.disposeBag)
        
        output.leaveRoomTemporary
                .subscribe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.destroyChatViewController()
                })
                .disposed(by: rx.disposeBag)
                
        output.memberLeft
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.roomStopped
            .drive(with: self, onNext: { weakSelf, _ in
                // Hide the error 'room ban'
                weakSelf.whiteboardViewController.view.isHidden = true
                weakSelf.showAlertWith(message: NSLocalizedString("Leaving room soon", comment: "")) {
                    weakSelf.leaveUIHierarchyAndStopSubModule()
                }
            })
            .disposed(by: rx.disposeBag)
                
        output.roomError
                .asDriver(onErrorJustReturn: "unknown reason")
                .drive(with: self, onNext: { weakSelf, reason in
                    weakSelf.showAlertWith(message: reason) {
                        weakSelf.leaveUIHierarchyAndStopSubModule()
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
                weakSelf.popoverViewController(viewController: weakSelf.inviteViewController, fromSource: weakSelf.inviteButton)
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
        
        whiteboardViewController.viewModel.isRoomJoined
            .asDriver(onErrorJustReturn: false)
            .filter { $0 }
            .flatMap { [weak self] _ -> Driver<Bool> in
                guard let self = self else { return .just(false) }
                return self.viewModel.isWhiteboardEnable
            }
            .drive(with: self, onNext: { weakSelf, enable in
                weakSelf.whiteboardViewController.updateToolsHide(!enable)
                weakSelf.whiteboardViewController.updatePageOperationHide(!enable)
                weakSelf.whiteboardViewController.viewModel.room.setWritable(enable) { _, _ in
                    if enable {
                        weakSelf.whiteboardViewController.viewModel.room.disableSerialization(false)
                    }
                }
                weakSelf.rightToolBar.updateButtonHide(weakSelf.cloudStorageButton, hide: !enable)
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
            leaveTap: settingVC.logoutButton.rx.sourceTap.asDriver().map { [unowned self] _ in self.settingButton },
            cameraTap: settingVC.cameraPublish.asDriver(onErrorJustReturn: ()),
            micTap: settingVC.micPublish.asDriver(onErrorJustReturn: ())))
        
        output.deviceTask
            .drive()
            .disposed(by: rx.disposeBag)
        
        output.dismiss.asObservable()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.leaveUIHierarchyAndStopSubModule()
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
    }
    
    func leaveUIHierarchyAndStopSubModule() {
        whiteboardViewController.viewModel.leave()
            .subscribe()
            .disposed(by: rx.disposeBag)
        rtcViewController.viewModel.rtc.leave()
            .subscribe()
            .disposed(by: rx.disposeBag)
        
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
    
    // MARK: - Lazy
    lazy var settingButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "classroom_setting")!)
        return button
    }()

    lazy var raiseHandButton: RaiseHandButton = {
        let button = RaiseHandButton(type: .custom)
        return button
    }()

    lazy var chatButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "chat")!)
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()
    
    lazy var usersButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "users")!)
        button.setupBadgeView(rightInset: 5, topInset: 5)
        return button
    }()

    @objc func onClickStorage(_ sender: UIButton) {
        popoverViewController(viewController: cloudStorageListViewController, fromSource: sender)
    }
    
    lazy var cloudStorageListViewController: CloudStorageListViewController = {
        let vc = CloudStorageListViewController()
        vc.fileContentSelectedHandler = { [weak self] fileContent in
            guard let self = self else { return }
            let whiteViewModel = self.whiteboardViewController.viewModel
            switch fileContent {
            case .image(url: let url, image: let image):
                whiteViewModel?.insertImg(url, imgSize: image.size)
            case .media(url: let url, title: let title):
                whiteViewModel?.insertMedia(url, title: title)
            case .multiPages(pages: let pages, title: let title):
                whiteViewModel?.insertMultiPages(pages, title: title)
            case .pptx(pages: let pages, title: let title):
                whiteViewModel?.insertPptx(pages, title: title)
            }
            self.dismiss(animated: true, completion: nil)
        }
        return vc
    }()
     
    lazy var cloudStorageButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "classroom_cloud")!)
        button.addTarget(self, action: #selector(onClickStorage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var inviteButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "invite")!)
        return button
    }()

    lazy var rightToolBar: RoomControlBar = {
        let bar = RoomControlBar(direction: .vertical,
                                 borderMask: [.layerMinXMinYCorner, .layerMinXMaxYCorner],
                                 buttons: [chatButton, cloudStorageButton, usersButton, inviteButton, settingButton],
                                 narrowStyle: .narrowMoreThan(count: 1))
        bar.updateButtonHide(cloudStorageButton, hide: true)
        return bar
    }()
}