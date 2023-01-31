//
//  ClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Fastboard
import RxCocoa
import RxSwift
import UIKit
import Whiteboard

let classRoomLeavingNotificationName = Notification.Name("classRoomLeaving")

class ClassRoomViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.hasCompact ? .landscapeRight : .landscape
    }

    func raiseHandButtonWidth() -> CGFloat {
        traitCollection.hasCompact ? 40 : 48
    }

    let isOwner: Bool
    let ownerUUID: String
    let viewModel: ClassRoomViewModel

    // MARK: - Child Controllers

    let fastboardViewController: FastboardViewController
    let rtcListViewController: RtcViewController
    let settingVC = ClassRoomSettingViewController(cameraOn: false, micOn: false, videoAreaOn: true, deviceUpdateEnable: false)
    let inviteViewController: () -> UIViewController
    let userListViewController: ClassRoomUsersViewController
    var chatVC: ChatViewController?
    lazy var raiseHandListViewController = RaiseHandListViewController()

    // MARK: - LifeCycle

    init(viewModel: ClassRoomViewModel,
         fastboardViewController: FastboardViewController,
         rtcListViewController: RtcViewController,
         userListViewController: ClassRoomUsersViewController,
         inviteViewController: @escaping () -> UIViewController,
         isOwner: Bool,
         ownerUUID: String,
         beginTime: Date)
    {
        self.viewModel = viewModel
        self.fastboardViewController = fastboardViewController
        self.rtcListViewController = rtcListViewController
        self.userListViewController = userListViewController
        self.inviteViewController = inviteViewController
        self.isOwner = isOwner
        self.ownerUUID = ownerUUID
        self.classroomStatusBar = .init(beginTime: beginTime)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        logger.trace("\(self) init")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        // Prevent iPad split compact window
        if isOnPadSplitCompactScreen {
            splitWarningsView.isHidden = false
            if splitWarningsView.superview == nil {
                // SetupWarning view one time
                let icon = UIImageView(image: UIImage(named: "login_icon"))
                splitWarningsView.contentView.addSubview(icon)
                icon.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                }
                let label = UILabel()
                label.text = localizeStrings("SplitScreenWarnings")
                label.textColor = .color(type: .text)
                splitWarningsView.contentView.addSubview(label)
                label.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(icon.snp.bottom).offset(14)
                }
                view.addSubview(splitWarningsView)
                splitWarningsView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        } else {
            splitWarningsView.isHidden = true
        }
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if container.superview != nil {
            updateLayout()
        }
    }

    deinit {
        logger.trace("\(self) deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        initRoomStatus()
        observeScene()
    }

    // MARK: - Private

    func initRoomStatus() {
        // Only status is required
        // Other service can join later
        let result = viewModel.initialRoomStatus()

        result.initRoomResult
            .do(
                onSuccess: { [weak self] in
                    self?.view.endFlatLoading()
                },
                onSubscribed: { [weak self] in
                    self?.view.startFlatLoading(showCancelDelay: 7, cancelCompletion: { [weak self] in
                        self?.stopSubModulesAndLeaveUIHierarchy()
                    })
                }
            )
            .subscribe(
                with: self,
                onSuccess: { weakSelf, _ in
                    weakSelf.setupBinding()
                },
                onFailure: { weakSelf, error in
                    weakSelf.stopSubModules()
                    weakSelf.showAlertWith(message: localizeStrings("Init room error") + error.localizedDescription) {
                        weakSelf.leaveUIHierarchy()
                    }
                }
            ).disposed(by: rx.disposeBag)

        result.autoPickMemberOnStageOnce?
            .subscribe(with: self, onSuccess: { weakSelf, user in
                if let user {
                    weakSelf.toast(localizeStrings("ownerAutoOnStageTips") + user.name, timeInterval: 3, preventTouching: false)
                }
            }).disposed(by: rx.disposeBag)

        result.roomError
            .subscribe(with: self, onNext: { weakSelf, error in
                func loopToAlert() {
                    if let _ = weakSelf.presentedViewController {
                        logger.trace("delay room error alert \(error)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            loopToAlert()
                        }
                    } else {
                        weakSelf.showAlertWith(message: error.uiAlertString) {
                            weakSelf.stopSubModulesAndLeaveUIHierarchy()
                        }
                    }
                }
                loopToAlert()
            }).disposed(by: rx.disposeBag)
    }

    func setupBinding() {
        bindUsersList()
        bindRtc()
        bindWhiteboard()
        bindSetting()
        bindChat()
        bindTerminate()
        bindInvite()
        bindStatusBar()

        if isOwner {
            bindDeviceResponse()
            bindRecording()
            bindRaiseHandList()
        } else {
            bindDeviceRequest()
            bindDeviceNotifyOff()
            // Only Teacher can stop the class,
            // So Teacher do not have to receive the alert
            bindStoped()
            bindUserRaiseHand()
        }
    }

    func bindDeviceNotifyOff() {
        viewModel.listeningDeviceNotifyOff()
            .drive(with: self) { weakSelf, s in
                weakSelf.toast(s)
            }
            .disposed(by: rx.disposeBag)
    }

    func bindDeviceResponse() {
        viewModel
            .listeningDeviceResponse()
            .drive(with: self) { weakSelf, toast in
                if toast.isEmpty { return }
                weakSelf.toast(toast)
            }
            .disposed(by: rx.disposeBag)
    }

    func bindDeviceRequest() {
        viewModel
            .listeningDeviceRequest()
            .drive()
            .disposed(by: rx.disposeBag)
    }

    func bindStoped() {
        viewModel.roomStoped
            .take(1)
            .subscribe(with: self, onNext: { weakSelf, _ in
                // Hide the error 'room ban'
                weakSelf.fastboardViewController.view.isHidden = true
                if let _ = weakSelf.presentedViewController { weakSelf.dismiss(animated: false, completion: nil) }
                weakSelf.showAlertWith(message: localizeStrings("Leaving room soon")) {
                    weakSelf.stopSubModulesAndLeaveUIHierarchy()
                }
            })
            .disposed(by: rx.disposeBag)
    }

    func bindRaiseHandList() {
        let raiseHandUsers = viewModel.members
            .map { ms in
                ms.filter(\.status.isRaisingHand)
            }
        raiseHandListViewController.raiseHandUsers = raiseHandUsers

        raiseHandUsers
            .asDriver(onErrorJustReturn: [])
            .map(\.count)
            .drive(with: self, onNext: { weakSelf, c in
                weakSelf.raiseHandListButton.isSelected = c > 0
                weakSelf.raiseHandListButton.updateBadgeHide(c <= 0, count: c)
            })
            .disposed(by: rx.disposeBag)

        raiseHandListButton.rx.tap
            .asDriver()
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.popoverViewController(viewController: weakSelf.raiseHandListViewController,
                                               fromSource: weakSelf.raiseHandListButton,
                                               permittedArrowDirections: .none)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindRecording() {
        let output = viewModel.transformRecordTap(recordButton.rx.tap)

        output.recording
            .skip(while: { !$0 })
            .asDriver(onErrorJustReturn: false)
            .do(onNext: { [weak self] recording in
                self?.toast(localizeStrings(recording ? "RecordingStartTips" : "RecordingEndTips"))
            })
            .drive(recordButton.rx.isSelected)
            .disposed(by: rx.disposeBag)

        output
            .loading
            .asDriver(onErrorJustReturn: false)
            .drive(recordButton.rx.isLoading)
            .disposed(by: rx.disposeBag)

        output.layoutUpdate
            .subscribe()
            .disposed(by: rx.disposeBag)
    }

    func bindTerminate() {
        NotificationCenter.default.rx.notification(UIApplication.willTerminateNotification)
            .subscribe(with: self, onNext: { weakSelf, _ in
                logger.info("device terminate")
                weakSelf.viewModel.destroy(sender: weakSelf)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindUserRaiseHand() {
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

        viewModel.transWhiteboardPermissionUpdate(whiteboardEnable: fastboardViewController.roomPermission.map(\.writable).asObservable())
            .drive(with: self, onNext: { weakSelf, toastString in
                weakSelf.toast(toastString, timeInterval: 3, preventTouching: false)
            })
            .disposed(by: rx.disposeBag)

        viewModel.transOnStageUpdate(whiteboardEnable: fastboardViewController.roomPermission.map(\.writable).asObservable())
            .subscribe(with: self, onNext: { weakSelf, toastString in
                weakSelf.toast(toastString, timeInterval: 3, preventTouching: false)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindStatusBar() {
        rtcListViewController.viewModel.rtc.lastMileDelay
            .subscribe(with: self) { ws, v in
                ws.classroomStatusBar.latency = v
            }
            .disposed(by: rx.disposeBag)

        rtcListViewController.viewModel.rtc.networkStatusBehavior
            .subscribe(with: self) { ws, q in
                switch q {
                case .excellent:
                    ws.classroomStatusBar.networkStatus = .great
                case .good:
                    ws.classroomStatusBar.networkStatus = .good
                default:
                    ws.classroomStatusBar.networkStatus = .bad
                }
            }
            .disposed(by: rx.disposeBag)
    }

    func bindInvite() {
        inviteButton.rx.tap
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.present(weakSelf.inviteViewController(), animated: true)
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
                let vc = ChatViewController(viewModel: chatViewModel, userRtmId: weakSelf.viewModel.userUUID, ownerRtmId: weakSelf.ownerUUID)
                vc.popOverDismissHandler = { [weak self] in
                    self?.chatButton.isSelected = false
                }
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
                weakSelf.chatButton.isSelected = true
                weakSelf.popoverViewController(viewController: vc,
                                               fromSource: weakSelf.chatButton,
                                               permittedArrowDirections: .none)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindUsersList() {
        userListViewController.popOverDismissHandler = { [weak self] in
            self?.usersButton.isSelected = false
        }

        let raiseHandCheckAll = raiseHandListViewController.checkAllPublisher
            .asObservable()
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self else { return .error("self not exist") }
                return self.rx.dismiss(animated: false).asObservable()
            }

        // Click raisehand list check all or click users will trigger user list viewcontroller
        Observable.merge(usersButton.rx.tap.asObservable(), raiseHandCheckAll)
            .subscribe(with: self, onNext: { weakSelf, _ in
                if weakSelf.traitCollection.hasCompact {
                    weakSelf.present(weakSelf.userListViewController, animated: true)
                } else {
                    weakSelf.usersButton.isSelected = true
                    weakSelf.popoverViewController(viewController: weakSelf.userListViewController,
                                                   fromSource: weakSelf.usersButton,
                                                   permittedArrowDirections: .none)
                }
            })
            .disposed(by: rx.disposeBag)

        userListViewController.users = viewModel.members

        viewModel.showUsersResPoint
            .subscribe(with: self, onNext: { weakSelf, show in
                weakSelf.usersButton.updateBadgeHide(!show)
            })
            .disposed(by: rx.disposeBag)

        viewModel.transformUserListInput(.init(allMuteTap: userListViewController.allMuteTap.asObservable(),
                                               stopInteractingTap: userListViewController.stopInteractingTap.asObservable(),
                                               tapSomeUserOnStage: userListViewController.onStageTap.asObservable(),
                                               tapSomeUserWhiteboard: userListViewController.whiteboardTap.asObservable(),
                                               tapSomeUserRaiseHand:
                                               Observable.merge([
                                                   userListViewController.raiseHandTap.asObservable(),
                                                   raiseHandListViewController.acceptRaiseHandPublisher.asObservable()
                                               ]),
                                               tapSomeUserCamera: userListViewController.cameraTap.asObservable(),
                                               tapSomeUserMic: userListViewController.micTap.asObservable()))
            .drive(with: self, onNext: { weakSelf, s in
                weakSelf.toast(s, timeInterval: 3, preventTouching: false)
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
                weakSelf.toast(localizeStrings(isOn ? "ScreenShare-On" : "ScreenShare-Off"))
                weakSelf.turnScreenShare(on: isOn)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindWhiteboard() {
        fastboardViewController.bind(observablePermission: viewModel.whiteboardPermission)
            .subscribe(with: self, onNext: { weakSelf, permission in
                weakSelf.rightToolBar.forceUpdate(button: weakSelf.cloudStorageButton, visible: permission.inputEnable)
            })
            .disposed(by: rx.disposeBag)

        fastboardViewController.appsClickHandler = { [weak self] room, button in
            guard let self else { return }
            let vc = WhiteboardAppsViewController()
            vc.clickSource = button
            vc.room = room
            self.popoverViewController(viewController: vc,
                                       fromSource: button,
                                       permittedArrowDirections: .none)
        }
    }

    func bindSetting() {
        settingVC.popOverDismissHandler = { [weak self] in
            self?.settingButton.isSelected = false
        }

        settingVC.shortcutsPublish
            .asObservable()
            .flatMap { [unowned self] in self.rx.dismiss(animated: true).asObservable() }
            .subscribe(with: self, onNext: { ws, _ in
                let vc = ShortcutsViewController()
                vc.popOverDismissHandler = {
                    ws.settingButton.isSelected = false
                }
                ws.settingButton.isSelected = true
                ws.popoverViewController(viewController: vc, fromSource: ws.settingButton)
            })
            .disposed(by: rx.disposeBag)

        settingButton.rx.controlEvent(.touchUpInside)
            .subscribe(with: self, onNext: { weakSelf, _ in
                weakSelf.settingButton.isSelected = true
                weakSelf.popoverViewController(viewController: weakSelf.settingVC,
                                               fromSource: weakSelf.settingButton,
                                               permittedArrowDirections: .none)
            })
            .disposed(by: rx.disposeBag)

        settingVC.videoAreaPublish.asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { weakSelf, _ in
                let isOpen = !weakSelf.settingVC.videoAreaOn.value
                weakSelf.settingVC.videoAreaOn.accept(isOpen)
                weakSelf.performRtc(hide: !isOpen)
            })
            .disposed(by: rx.disposeBag)

        viewModel.transformLogoutTap(settingVC.logoutButton.rx.sourceTap.map { [unowned self] _ in
            self.settingButton
        })
        .subscribe(with: self, onNext: { weakSelf, dismiss in
            if dismiss {
                weakSelf.stopSubModulesAndLeaveUIHierarchy()
            }
        })
        .disposed(by: rx.disposeBag)

        viewModel.currentUser.map(\.status.isSpeak)
            .asDriver(onErrorJustReturn: false)
            .drive(settingVC.deviceUpdateEnable)
            .disposed(by: rx.disposeBag)

        viewModel.currentUser
            .map(\.status.camera)
            .asDriver(onErrorJustReturn: false)
            .drive(settingVC.cameraOn)
            .disposed(by: rx.disposeBag)

        viewModel.currentUser
            .map(\.status.mic)
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

    lazy var rtcAndBoardContainer: UIStackView = {
        let rtcView = rtcListViewController.view!
        let boardView = fastboardViewController.view!
        let mainContentContainer: UIStackView
        if UIDevice.current.userInterfaceIdiom == .phone {
            mainContentContainer = UIStackView(arrangedSubviews: [boardView, rtcView])
            mainContentContainer.axis = .horizontal
        } else {
            mainContentContainer = UIStackView(arrangedSubviews: [rtcView, boardView])
            mainContentContainer.axis = .vertical
        }
        return mainContentContainer
    }()

    lazy var container: UIStackView = {
        let container = UIStackView(arrangedSubviews: [classroomStatusBar, rtcAndBoardContainer])
        container.axis = .vertical
        return container
    }()

    func setupViews() {
        view.backgroundColor = .color(type: .background)
        addChild(fastboardViewController)
        addChild(rtcListViewController)

        let rtcView = rtcListViewController.view!
        let boardView = fastboardViewController.view!

        view.addSubview(container)
        fastboardViewController.didMove(toParent: self)
        rtcListViewController.didMove(toParent: self)

        let isiPhone = UIDevice.current.userInterfaceIdiom == .phone
        let statusBarMinHeight: CGFloat = 24
        let statusBarMaxHeight: CGFloat = 66
        
        container.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(view.safeAreaInsets.left / 2)
            make.width.lessThanOrEqualTo(view).inset(view.safeAreaInsets.left / 2)
            make.height.lessThanOrEqualToSuperview()
            make.width.height.equalToSuperview().priority(.high)
        }
        classroomStatusBar.snp.makeConstraints { make in
            make.height.lessThanOrEqualTo(statusBarMaxHeight)
            make.height.greaterThanOrEqualTo(statusBarMinHeight)
            make.height.equalTo(statusBarMinHeight).priority(.low)
        }

        if isiPhone {
            boardView.snp.makeConstraints { make in
                make.width.equalTo(boardView.snp.height).dividedBy(ClassRoomLayoutRatioConfig.whiteboardRatio)
                make.height.equalTo(view).offset(statusBarMinHeight).priority(.low)
            }
            let iPhoneMinRtcWidth: CGFloat = 120
            rtcView.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(iPhoneMinRtcWidth)
                make.width.equalTo(iPhoneMinRtcWidth).priority(.medium)
            }
        } else {
            let rtcMinHeight: CGFloat = 88
            let rtcMaxHeight: CGFloat = 190
            rtcView.snp.makeConstraints { make in
                make.height.lessThanOrEqualTo(rtcMaxHeight)
                make.height.greaterThanOrEqualTo(rtcMinHeight)
                make.height.equalTo(rtcMaxHeight).priority(.medium)
            }
            boardView.snp.makeConstraints { make in
                make.height.equalTo(boardView.snp.width).multipliedBy(ClassRoomLayoutRatioConfig.whiteboardRatio)
                make.width.equalTo(view).priority(.low)
            }
        }

        setupToolbar()
    }

    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            make.right.equalTo(fastboardViewController.view.snp.right).inset(8)
            make.centerY.equalTo(fastboardViewController.view)
        }

        if !isOwner {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.width.height.equalTo(raiseHandButtonWidth())
                make.centerX.equalTo(rightToolBar)
                make.top.equalTo(rightToolBar.snp.bottom).offset(12)
            }
        } else {
            view.addSubview(raiseHandListButton)
            raiseHandListButton.snp.makeConstraints { make in
                make.width.height.equalTo(raiseHandButtonWidth())
                make.centerX.equalTo(rightToolBar)
                make.top.equalTo(rightToolBar.snp.bottom).offset(12)
            }
        }
    }

    func stopSubModules() {
        viewModel.destroy(sender: self)
        fastboardViewController.leave()
        rtcListViewController.viewModel.rtc
            .leave()
            .subscribe()
            .disposed(by: rx.disposeBag)
    }

    func leaveUIHierarchy() {
        if let session = view.window?.windowScene?.session,
           view.window?.rootViewController === self
        {
            UIApplication.shared.requestSceneSessionDestruction(session,
                                                                options: nil)
            return
        }
        if let presenting = presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
        }
    }

    func stopSubModulesAndLeaveUIHierarchy() {
        stopSubModules()
        leaveUIHierarchy()
    }

    // MARK: - Scene

    func observeScene() {
        NotificationCenter.default.addObserver(self, selector: #selector(onSceneDisconnect(notification:)), name: UIScene.didDisconnectNotification, object: nil)
    }

    @objc func onSceneDisconnect(notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        if view.window?.windowScene === scene {
            logger.info("classroom destroy by scene disconnect")
            viewModel.destroy(sender: self)
        }
    }

    // MARK: - Layout
    func updateLayout() {
        if settingVC.videoAreaOn.value {
            // Do not use the left safe area.
            // Mostly, it was iPhone with fringe.
            container.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset(view.safeAreaInsets.left / 2)
                make.width.lessThanOrEqualTo(view).inset(view.safeAreaInsets.left / 2)
            }
        } else {
            container.snp.updateConstraints { make in
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(view).inset(view.safeAreaInsets.left / 2)
            }
        }
    }
    
    func performRtc(hide: Bool) {
        rtcAndBoardContainer.sendSubviewToBack(rtcListViewController.view)
        self.rtcListViewController.view.alpha = hide ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            self.rtcListViewController.view.alpha = hide ? 0: 1
            self.rtcListViewController.view.isHidden = hide
            self.updateLayout()
        }
    }

    // MARK: - Lazy

    lazy var settingButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_setting")!
        return button
    }()

    lazy var recordButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_record")!
        button.style = .selectableAppliance
        return button
    }()

    lazy var raiseHandListButton: UIButton = {
        let button = UIButton(type: .custom)
        let circle = UIView()
        button.addSubview(circle)
        circle.layer.borderWidth = commonBorderWidth
        circle.layer.cornerRadius = raiseHandButtonWidth() / 2
        circle.clipsToBounds = true
        circle.isUserInteractionEnabled = false
        circle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        button.setupBadgeView(rightInset: -6, topInset: -6, width: 20)
        button.setTraitRelatedBlock { btn in
            btn.setImage(UIImage(named: "raisehand")?.tintColor(.color(type: .text)), for: .normal)
            btn.setImage(UIImage(named: "raisehand")?.tintColor(.color(type: .primary)), for: .selected)
            circle.layer.borderColor = UIColor.borderColor.cgColor
        }
        return button
    }()

    lazy var raiseHandButton: UIButton = {
        let button = UIButton(type: .custom)
        let circle = UIView()
        button.addSubview(circle)
        circle.layer.borderWidth = commonBorderWidth
        circle.layer.cornerRadius = raiseHandButtonWidth() / 2
        circle.clipsToBounds = true
        circle.isUserInteractionEnabled = false
        circle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        button.setTraitRelatedBlock { btn in
            btn.setImage(UIImage(named: "raisehand")?.tintColor(.color(type: .text)), for: .normal)
            btn.setImage(UIImage(named: "raisehand")?.tintColor(.color(type: .primary)), for: .highlighted)
            btn.setImage(UIImage(named: "raisehand")?.tintColor(.color(type: .primary)), for: .selected)
            circle.layer.borderColor = UIColor.borderColor.cgColor
        }
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
        cloudStorageNavigationController.popOverDismissHandler = { [weak self] in
            self?.cloudStorageButton.isSelected = false
        }
        cloudStorageButton.isSelected = true
        popoverViewController(viewController: cloudStorageNavigationController,
                              fromSource: sender,
                              permittedArrowDirections: .none)
    }

    lazy var cloudStorageNavigationController = BaseNavigationViewController(rootViewController: cloudStorageListViewController)

    lazy var cloudStorageListViewController: CloudStorageInClassViewController = {
        let vc = CloudStorageInClassViewController()
        vc.fileContentSelectedHandler = { [weak self] fileContent in
            guard let self else { return }
            switch fileContent {
            case let .image(url: url, image: image):
                let imageSize = image.size
                let cameraScale = self.fastboardViewController.fastRoom.room?.state.cameraState?.scale.floatValue ?? 1
                let containerWidth = self.fastboardViewController.fastRoom.view.bounds.width / 4 / CGFloat(cameraScale)
                if imageSize.width > containerWidth {
                    let ratio = imageSize.width / imageSize.height
                    self.fastboardViewController.fastRoom.insertImg(url, imageSize: .init(width: containerWidth, height: containerWidth / ratio))
                } else {
                    self.fastboardViewController.fastRoom.insertImg(url, imageSize: image.size)
                }
                let newMemberState = WhiteMemberState()
                newMemberState.currentApplianceName = .ApplianceSelector
                self.fastboardViewController.fastRoom.room?.setMemberState(newMemberState)
                self.fastboardViewController.fastRoom.view.overlay?.initUIWith(appliance: .ApplianceSelector, shape: nil)
            case let .media(url: url, title: title):
                self.fastboardViewController.fastRoom.insertMedia(url, title: title, completionHandler: nil)
            case let .multiPages(pages: pages, title: title):
                self.fastboardViewController.fastRoom.insertStaticDocument(pages, title: title, completionHandler: nil)
            case let .pptx(pages: pages, title: title):
                self.fastboardViewController.fastRoom.insertPptx(pages, title: title, completionHandler: nil)
            case let .projectorPptx(uuid: uuid, prefix: prefix, title: title):
                self.fastboardViewController.fastRoom.insertPptx(uuid: uuid, url: prefix, title: title)
            }
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
                                         borderMask: .all,
                                         views: [chatButton, usersButton, inviteButton, cloudStorageButton, settingButton])
            bar.forceUpdate(button: cloudStorageButton, visible: false)
            bar.forceUpdate(button: chatButton, visible: false)
            bar.narrowStyle = .none
            return bar
        } else {
            let bar = FastRoomControlBar(direction: .vertical,
                                         borderMask: .all,
                                         views: [chatButton, usersButton, inviteButton, cloudStorageButton, settingButton, recordButton])
            bar.forceUpdate(button: cloudStorageButton, visible: false)
            bar.forceUpdate(button: chatButton, visible: false)
            bar.forceUpdate(button: recordButton, visible: isOwner)
            return bar
        }
    }()

    lazy var screenShareView: UIView = {
        let view = UIView()
        view.backgroundColor = .color(type: .background)
        return view
    }()

    lazy var splitWarningsView: UIVisualEffectView = {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        return effectView
    }()

    let classroomStatusBar: ClassroomStatusBar
}
