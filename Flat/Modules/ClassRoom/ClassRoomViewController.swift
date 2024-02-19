//
//  ClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import MBProgressHUD
import Fastboard
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import Whiteboard

let classRoomLeavingNotificationName = Notification.Name("classRoomLeaving")
let classRoomListNeedRefreshNotificationName = Notification.Name("classRoomListNeedRefresh")

let classroomStatusBarMinHeight: CGFloat = 24
let classroomRtcMinHeight: CGFloat = 88
let classroomRtcMaxHeight: CGFloat = 190
let classroomRtcMinWidth: CGFloat = 120
let classroomRtcMaxWidth: CGFloat = 166
let classroomRtcComactLength: CGFloat = 0

class ClassRoomViewController: UIViewController {
    var hideStatusBar = true
    override var prefersStatusBarHidden: Bool {
        hideStatusBar
    }
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

    // MARK: - Rtc dragging variables

    var rtcIndicatorDraggingPreviousTranslation = CGFloat(0)
    var draggingTranslation = CGFloat(0)
    var rtcLengthConstraint: Constraint?
    var draggingStartRtcLength = CGFloat(0)

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
        classroomStatusBar = .init(beginTime: beginTime)
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
        becomeFirstResponder()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 14.0, *) {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                return
            }
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            hideStatusBar = container.frame.origin.y <= view.safeAreaInsets.top
            setNeedsStatusBarAppearanceUpdate()
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
                    guard let self else { return }
                    self.view.endFlatLoading {
                        if self.viewModel.roomTimeLimit > 0 {
                            let msg = String(format: NSLocalizedString("FreeRoomTimeLimitTip %@", comment: "free room time limit tips"), self.viewModel.roomTimeLimit.description)
                            self.toast(msg, timeInterval: 3, offset: .init(x: 0, y: MBProgressMaxOffset), hidePreviouds: false)
                        }
                    }
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
                    weakSelf.stopSubModules(cleanRtc: true)
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
                weakSelf.stopSubModules(cleanRtc: false) // Clean rtc by system.
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
                case .unknown:
                    ws.classroomStatusBar.networkStatus = .great
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
                r.toast
                    .asDriver(onErrorJustReturn: "")
                    .drive(with: self) { ws, msg in
                        ws.toast(msg, timeInterval: 3)
                    }
                    .disposed(by: weakSelf.rx.disposeBag)
                
                let chatViewModel = ChatViewModel(roomUUID: weakSelf.viewModel.roomUUID,
                                                  userNameProvider: r.userNameProvider,
                                                  rtmChannel: r.channel,
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

                // To trigger bind function
                vc.loadViewIfNeeded()
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

        let tapSomeUserCamera = Observable.merge(
            userListViewController.cameraTap.asObservable().map(\.rtmUUID),
            settingVC.cameraPublish.asObservable().map { [unowned self] in self.viewModel.userUUID },
            rtcListViewController.userCameraClick.asObservable()
        )

        let tapSomeUserMic = Observable.merge(
            userListViewController.micTap.asObservable().map(\.rtmUUID),
            settingVC.micPublish.asObservable().map { [unowned self] in self.viewModel.userUUID },
            rtcListViewController.userMicClick.asObservable()
        )

        let whiteboardTap = Observable.merge(
            rtcListViewController.whiteboardClick.asObservable(),
            userListViewController.whiteboardTap.asObservable()
        )

        let muteAll = Observable.merge(
            rtcListViewController.muteAllClick.asObservable(),
            userListViewController.allMuteTap.asObservable()
        )

        viewModel.transformUserListInput(.init(allMuteTap: muteAll,
                                               stopInteractingTap: userListViewController.stopInteractingTap.asObservable(),
                                               tapSomeUserOnStage: userListViewController.onStageTap.asObservable(),
                                               tapSomeUserWhiteboard: whiteboardTap,
                                               tapSomeUserRaiseHand:
                                               Observable.merge([
                                                   userListViewController.raiseHandTap.asObservable(),
                                                   raiseHandListViewController.acceptRaiseHandPublisher.asObservable(),
                                               ]),
                                               tapSomeUserCamera: tapSomeUserCamera,
                                               tapSomeUserMic: tapSomeUserMic,
                                               tapSomeUserReward: rtcListViewController.rewardsClick.asObservable()))
            .drive(with: self, onNext: { weakSelf, s in
                weakSelf.toast(s, timeInterval: 3, preventTouching: false)
            })
            .disposed(by: rx.disposeBag)
    }

    func bindRtc() {
        viewModel
            .members
            .map { $0.filter(\.status.isSpeak).count }
            .map { localizeStrings("People on stage hint") + " \($0)" }
            .bind(to: classroomStatusBar.onStageStatusButton.rx.title(for: .normal))
            .disposed(by: rx.disposeBag)

        rtcListViewController.bindUsers(viewModel.members.asDriver(onErrorJustReturn: []))
        rtcListViewController.draggingCanvasProvider = self

        viewModel
            .observableRewards()
            .subscribe(with: rtcListViewController) { r, uid in
                r.rewardAnimation(uid: uid)
            }
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
                weakSelf.rightToolBar.forceUpdate(button: weakSelf.takePhotoButton, visible: permission.inputEnable)
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

        settingVC.preferencePublish
            .asObservable()
            .flatMap { [unowned self] in self.rx.dismiss(animated: true).asObservable() }
            .subscribe(with: self, onNext: { ws, _ in
                let vc = PreferenceViewController()
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

        Driver.merge(
            classroomStatusBar.onStageStatusButton.rx.tap.asDriver(),
            settingVC.videoAreaPublish.asDriver(onErrorJustReturn: ())
        )
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
        mainContentContainer.bringSubviewToFront(boardView) // To let video drag zIndex property.
        return mainContentContainer
    }()

    lazy var container: UIStackView = {
        let container = UIStackView(arrangedSubviews: [classroomStatusBar, rtcAndBoardContainer])
        container.axis = .vertical
        container.bringSubviewToFront(classroomStatusBar)
        container.clipsToBounds = true
        return container
    }()

    lazy var draggingDridMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isHidden = true
        return view
    }()

    func setupViews() {
        view.backgroundColor = .color(type: .background)
        addChild(rtcListViewController)
        addChild(fastboardViewController)

        let boardView = fastboardViewController.view!

        view.addSubview(draggingDridMaskView) // Make sure the container is on the bottom hierachy.
        view.addSubview(container)
        rtcListViewController.didMove(toParent: self)
        fastboardViewController.didMove(toParent: self)

        let isiPhone = UIDevice.current.userInterfaceIdiom == .phone

        draggingDridMaskView.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.bottom.equalTo(fastboardViewController.blackMaskView)
        }

        container.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(view.safeAreaInsets.left / 2) // Only work for some iPhone.
            make.width.lessThanOrEqualTo(view).inset(view.safeAreaInsets.left / 2)
            make.height.lessThanOrEqualToSuperview()
            make.width.height.equalToSuperview().priority(.high)
        }

        classroomStatusBar.snp.remakeConstraints { make in
            make.height.equalTo(classroomStatusBarMinHeight)
        }

        if isiPhone {
            boardView.snp.makeConstraints { make in
                make.width.equalTo(boardView.snp.height).dividedBy(ClassRoomLayoutRatioConfig.whiteboardRatio)
                make.height.equalTo(view).offset(classroomStatusBarMinHeight).priority(.low)
            }
        } else {
            boardView.snp.makeConstraints { make in
                make.height.equalTo(boardView.snp.width).multipliedBy(ClassRoomLayoutRatioConfig.whiteboardRatio)
                make.width.equalTo(view).priority(.low)
            }
        }

        // Keep dragging view order lower than operation panel.
        setupRtcDragging()
        setupToolbar()
        updateRtcViewConstraint()
    }

    /// - Parameter length: width for vertical. height for horizontal
    func updateRtcViewConstraint(length: CGFloat? = nil) {
        guard let rtcView = rtcListViewController.view else { return }
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        if isPhone {
            rtcLengthConstraint?.deactivate()
            rtcView.snp.remakeConstraints { make in
                if let length {
                    rtcLengthConstraint = make.width.equalTo(length).constraint
                } else {
                    make.width.greaterThanOrEqualTo(classroomRtcMinWidth)
                    rtcLengthConstraint = make.width.equalTo(classroomRtcMinWidth).priority(.medium).constraint
                }
            }
        } else {
            rtcLengthConstraint?.deactivate()
            rtcView.snp.remakeConstraints { make in
                make.height.lessThanOrEqualTo(classroomRtcMaxHeight)
                make.height.greaterThanOrEqualTo(classroomRtcMinHeight)
                if let length {
                    rtcLengthConstraint = make.height.equalTo(length).constraint
                } else {
                    rtcLengthConstraint = make.height.equalTo(classroomRtcMaxHeight).priority(.medium).constraint
                }
            }
        }
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

    // Clean rtc may made crash when app is terminating.
    func stopSubModules(cleanRtc: Bool) {
        viewModel.destroy(sender: self)
        fastboardViewController.leave()
        if cleanRtc {
            rtcListViewController.viewModel.rtc
                .leave()
                .subscribe()
                .disposed(by: rx.disposeBag)
        }
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
        stopSubModules(cleanRtc: true)
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
            stopSubModules(cleanRtc: true)
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

    func performRtc(hide: Bool, animation: Bool = true) {
        updateRtcViewConstraint(length: hide ? classroomRtcComactLength : nil)
        let animationBlock: (() -> Void) = {
            self.rtcListViewController.mainScrollView.alpha = hide ? 0 : 1
            self.classroomStatusBar.onStageStatusButton.alpha = hide ? 1 : 0
            self.view.layoutIfNeeded()
        }
        if animation {
            UIView.animate(withDuration: 0.3, animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    // MARK: - Lazy

    lazy var rtcDraggingHandlerView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.alpha = 0.3
        view.isUserInteractionEnabled = true
        view.contentMode = .center
        return view
    }()

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

    lazy var takePhotoButton: FastRoomPanelItemButton = {
        let button = FastRoomPanelItemButton(type: .custom)
        button.rawImage = UIImage(named: "classroom_take_photo")!
        button.addTarget(self, action: #selector(onClickTakePhoto(_:)), for: .touchUpInside)
        return button
    }()

    lazy var raiseHandListButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setupBadgeView(rightInset: -6, topInset: -6, width: 20)
        button.setImage(UIImage(named: "raisehand_normal"), for: .normal)
        button.setImage(UIImage(named: "raisehand_selected"), for: .selected)
        return button
    }()

    lazy var raiseHandButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "raisehand_normal"), for: .normal)
        button.setImage(UIImage(named: "raisehand_selected"), for: .selected)
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

    @objc func onClickTakePhoto(_: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.modalPresentationStyle = .pageSheet
        picker.delegate = self
        present(picker, animated: true)
    }

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
                self.fastboardViewController.insert(image: image, url: url)
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
                                         views: [takePhotoButton, chatButton, usersButton, inviteButton, cloudStorageButton, settingButton])
            bar.forceUpdate(button: takePhotoButton, visible: false)
            bar.forceUpdate(button: cloudStorageButton, visible: false)
            bar.forceUpdate(button: chatButton, visible: false)
            bar.narrowStyle = .none
            return bar
        } else {
            let bar = FastRoomControlBar(direction: .vertical,
                                         borderMask: .all,
                                         views: [takePhotoButton, chatButton, usersButton, inviteButton, cloudStorageButton, recordButton, settingButton])
            bar.forceUpdate(button: takePhotoButton, visible: false)
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

extension ClassRoomViewController: VideoDraggingCanvasProvider {
    func getDraggingView() -> UIView { fastboardViewController.view }
    func getDraggingLayoutFor(index: Int, totalCount: Int) -> CGRect {
        let bounds = getDraggingView().bounds
        let colCount: Int
        switch totalCount {
        case 1: colCount = 1
        case 2 ... 4: colCount = 2
        case 5 ... 9: colCount = 3
        default: colCount = 4
        }
        let rowCount = ceil(CGFloat(totalCount) / CGFloat(colCount))
        let rowIndex = CGFloat(index / colCount)
        let colIndex = CGFloat(index % colCount)
        let itemWidth = bounds.width / CGFloat(colCount)
        let itemHeight = bounds.height / CGFloat(rowCount)
        var videoSize: CGSize
        let estimateWidth = itemHeight / ClassRoomLayoutRatioConfig.rtcPreviewRatio
        if estimateWidth <= itemWidth {
            videoSize = .init(width: estimateWidth, height: itemHeight)
        } else {
            let videoHeight = itemWidth * ClassRoomLayoutRatioConfig.rtcPreviewRatio
            videoSize = .init(width: itemWidth, height: videoHeight)
        }

        videoSize = .init(width: floor(videoSize.width), height: floor(videoSize.height)) // Round to prevent pixel error.

        let horizontalSpacing = bounds.height - (videoSize.height * rowCount)
        let topMargin = floor(horizontalSpacing / 2)

        let needCenterLastRow = totalCount % colCount != 0 // Center last row
        let isLastRow = rowIndex == rowCount - 1
        let y = topMargin + (rowIndex * videoSize.height)
        if needCenterLastRow, isLastRow {
            let actualLastColCount = CGFloat(totalCount % colCount)
            let widthMargin = (bounds.width - (actualLastColCount * itemWidth)) / 2
            let x = widthMargin + (colIndex * itemWidth) + (itemWidth - videoSize.width) / 2
            let rect = CGRect(x: x, y: y, width: videoSize.width, height: videoSize.height)
            return rect
        } else {
            let x = (colIndex * itemWidth) + (itemWidth - videoSize.width) / 2
            let rect = CGRect(x: x, y: y, width: videoSize.width, height: videoSize.height)
            return rect
        }
    }

    func onStartGridPreview() {
        fastboardViewController.blackMaskView.isHidden = false
        draggingDridMaskView.isHidden = false
    }

    func onEndGridPreview() {
        fastboardViewController.blackMaskView.isHidden = true
        draggingDridMaskView.isHidden = true
    }

    func startHint() {
        fastboardViewController.innerBorderMaskView.isHidden = false
        fastboardViewController.view.bringSubviewToFront(fastboardViewController.innerBorderMaskView)
    }

    func endHint() {
        fastboardViewController.innerBorderMaskView.isHidden = true
    }
}
