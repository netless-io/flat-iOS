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

class ClassRoomViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    var viewModel: ClassRoomViewModel!
    
    var chatVCDisposeBag = DisposeBag()
    
    // MARK: - Child Controllers
    let whiteboardViewController: WhiteboardViewController
    let rtcViewController: RtcViewController
    let settingVC = ClassRoomSettingViewController(cameraOn: false, micOn: false, videoAreaOn: true)
    let inviteViewController: InviteViewController
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
        self.inviteViewController = .init(roomTitle: roomTitle,
                                          roomTime: beginTime,
                                          roomEndTime: endTime,
                                          roomNumber: roomNumber,
                                          roomUUID: roomUUID,
                                          userName: userName)
        self.rtcViewController = rtcViewController
        self.whiteboardViewController = whiteboardViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        
        let alertProvider = DefaultAlertProvider(root: self) { [weak self] model in
            guard let self = self else {
                return (UIView(), .zero)
            }
            return (self.rightToolBar, self.rightToolBar.bounds.insetBy(dx: -10, dy: 0))
        }
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        bindGeneral()
        bindUsers()
        bindRtc()
        bindUserList()
        bindSetting()
        bindInteracting()

        if viewModel.isTeacher {
            bindTeacherOperations()
        }
    }
    
    // MARK: - Private Setup
    func setupViews() {
        view.backgroundColor = .init(hexString: "#F7F9FB")
        addChild(whiteboardViewController)
        addChild(rtcViewController)
        let horizontalLine = UIView(frame: .zero)
        horizontalLine.backgroundColor = .popoverBorder
        
        let stackView = UIStackView(arrangedSubviews: [rtcViewController.view,
                                                       horizontalLine,
                                                       whiteboardViewController.view
                                                       ])
        stackView.axis = .vertical
        stackView.distribution = .fill
        view.addSubview(stackView)
        
        whiteboardViewController.didMove(toParent: self)
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
        
        setupToolbar()
    }
    
    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            make.right.equalTo(whiteboardViewController.view.snp.right)
            make.centerY.equalTo(whiteboardViewController.view)
        }
        let seperateLine = UIView()
        seperateLine.backgroundColor = .borderColor
        view.addSubview(seperateLine)
        seperateLine.snp.makeConstraints { make in
            make.left.equalTo(whiteboardViewController.view.snp.right)
            make.top.bottom.equalTo(whiteboardViewController.view)
            make.width.equalTo(1)
        }
        if viewModel.isTeacher {
            view.addSubview(teacherOperationStackView)
            teacherOperationStackView.snp.makeConstraints { make in
                make.top.equalTo(whiteboardViewController.view).offset(10)
                make.centerX.equalTo(whiteboardViewController.view)
            }
        } else {
            view.addSubview(raiseHandButton)
            raiseHandButton.snp.makeConstraints { make in
                make.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(28)
            }
        }
    }
    
    func destoryChatViewContrller() {
        print("destory chatVC")
        chatVC?.dismiss(animated: false, completion: nil)
        chatButton.isHidden = false
        chatVC = nil
        chatVCDisposeBag = DisposeBag()
    }
    
    func setupChatViewController() {
        print("setup chatVC")
        chatButton.isHidden = true
        let banNotice = viewModel.state.messageBan
            .skip(1)
            .map { return $0 ? "已禁言" : "已解除禁言" }
        
        // Is chat been banning, not include user self
        let banning = viewModel.state.messageBan.asDriver()
        
        // Is user benn banned
        let baned = viewModel.state.messageBan.map { [ weak self] in
            (self?.viewModel.isTeacher ?? false) ? false : $0
        }.asDriver(onErrorJustReturn: true)
        
        let showRedPoint = viewModel.rtm.joinChannelId(viewModel.chatChannelId)
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
                    self?.destoryChatViewContrller()
                })
                .disposed(by: rx.disposeBag)
                
        output.memberLeft
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.roomStopped
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.showAlertWith(message: "即将离开房间") {
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
        
        // Should show user red (when received raisehand while user panel is not presenting)
        let hideUserRedpointWhenNewRaiseHand = output.newCommand.filter {
            if case .raiseHand(let raise) = $0, raise { return true }
            return false
        }.flatMap { [weak self] _ -> Observable<Bool> in
            guard let vc = self?.usersViewController else { return .just(false) }
            return vc.rx.isPresented.asObservable()
        }.asDriver(onErrorJustReturn: true)
        
        Driver.of(hideUserRedpointWhenNewRaiseHand,
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
                weakSelf.whiteboardViewController.viewModel.room.setWritable(enable, completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func bindUserList() {
        viewModel.transformUserListInput(.init(stopInteractingTap: usersViewController.stopInteractingTap.asDriver(onErrorJustReturn: ()),
                                                         disconnectTap: usersViewController.disconnectTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserRaiseHand: usersViewController.raiseHandTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserCamera: usersViewController.camaraTap.asDriver(onErrorJustReturn: .emtpy),
                                                         tapSomeUserMic: usersViewController.micTap.asDriver(onErrorJustReturn: .emtpy)))
            .drive()
            .disposed(by: rx.disposeBag)
    }
    
    func bindTeacherOperations() {
        viewModel.state.startStatus
            .asDriver(onErrorJustReturn: .Idle)
            .drive(with: self, onNext: { weakSelf, status in
                // Teacher tool bar
                weakSelf.teacherOperationStackView.arrangedSubviews.forEach({
                    $0.removeFromSuperview()
                    weakSelf.teacherOperationStackView.removeArrangedSubview($0)
                })
                switch status {
                case .Idle:
                    weakSelf.teacherOperationStackView.addArrangedSubview(weakSelf.startButton)
                case .Paused:
                    weakSelf.teacherOperationStackView.addArrangedSubview(weakSelf.resumeButton)
                    weakSelf.teacherOperationStackView.addArrangedSubview(weakSelf.endButton)
                case .Started:
                    weakSelf.teacherOperationStackView.addArrangedSubview(weakSelf.pauseButton)
                    weakSelf.teacherOperationStackView.addArrangedSubview(weakSelf.endButton)
                default:
                    break
                }
            })
            .disposed(by: rx.disposeBag)
        
        let output = viewModel.tranfromTeacherInput(.init(startTap: startButton.rx.tap.asDriver(onErrorJustReturn: ()),
                                                                   resumeTap: resumeButton.rx.tap.asDriver(onErrorJustReturn: ()),
                                                                   endTap: endButton.rx.tap.asDriver(onErrorJustReturn: ()),
                                                                   pauseTap: pauseButton.rx.tap.asDriver(onErrorJustReturn: ())))
        
        output.taps
            .drive()
            .disposed(by: rx.disposeBag)
        
        output.starting
            .drive(with: self, onNext: { weakSelf, starting in
                let title = NSLocalizedString("Start Class", comment: "")
                if starting {
                    weakSelf.startButton.setTitle(title + "...", for: .normal)
                } else {
                    weakSelf.startButton.setTitle(title, for: .normal)
                }
                weakSelf.startButton.isEnabled = !starting
            })
            .disposed(by: rx.disposeBag)
        
        output.pausing
            .drive(with: self, onNext: { weakSelf, pausing in
                let title = NSLocalizedString("Pause Class", comment: "")
                if pausing {
                    weakSelf.pauseButton.setTitle(title + "...", for: .normal)
                } else {
                    weakSelf.pauseButton.setTitle(title, for: .normal)
                }
                weakSelf.pauseButton.isEnabled = !pausing
            })
            .disposed(by: rx.disposeBag)
        
        output.resuming
            .drive(with: self, onNext: { weakSelf, resuming in
                let title = NSLocalizedString("Resume Class", comment: "")
                if resuming {
                    weakSelf.resumeButton.setTitle(title + "...", for: .normal)
                } else {
                    weakSelf.resumeButton.setTitle(title, for: .normal)
                }
                weakSelf.resumeButton.isEnabled = !resuming
            })
            .disposed(by: rx.disposeBag)
        
        output.stopping
            .drive(with: self, onNext: { weakSelf, stopping in
                let title = NSLocalizedString("Stop Class", comment: "")
                if stopping {
                    weakSelf.endButton.setTitle(title + "...", for: .normal)
                } else {
                    weakSelf.endButton.setTitle(title, for: .normal)
                }
                weakSelf.endButton.isEnabled = !stopping
            })
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
                    let hide = weakSelf.rtcViewController.view.isHidden
                    weakSelf.settingVC.videoAreaOn.accept(hide)
                    UIView.animate(withDuration: 0.3) {
                        weakSelf.rtcViewController.view.isHidden = !hide
                    }
                })
                .disposed(by: rx.disposeBag)
        
        let output = viewModel.transformSetting(.init(
            leaveTap:settingVC.logoutButton.rx.sourceTap.asDriver(),
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
        if let presenting = presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Lazy
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
        return btn
    }()

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
            }
        }
        return vc
    }()
     
    lazy var cloudStorageButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "tab_cloud_storage")!)
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
                                 buttons: viewModel.isTeacher ? [chatButton, cloudStorageButton, usersButton, inviteButton, settingButton] : [chatButton, usersButton, inviteButton, settingButton],
                                 narrowStyle: .narrowMoreThan(count: 1))
        return bar
    }()
}
