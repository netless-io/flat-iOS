//
//  ClassRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Whiteboard

class ClassRoomViewController: UIViewController {
    let roomPlayInfo: RoomPlayInfo
    let roomInfo: RoomInfo
    var roomStatus: RoomStatus? {
        didSet {
            updateViewsWithRoomStatus(roomStatus)
        }
    }
    
    // The current user status
    var userStatus: RoomUserStatus {
        didSet {
            // Raise hand
            if userStatus.isRaisingHand != oldValue.isRaisingHand {
                do {
                    try rtm.sendCommand(.raiseHand(userStatus.isRaisingHand), toTargetUID: nil)
                    self.toast(userStatus.isRaisingHand ? "你已举手" : "你已取消举手")
                }
                catch {
                    print("raise hand error \(error)")
                }
            }
            if userStatus.camera != oldValue.camera || userStatus.mic != oldValue.mic {
                // Device status
                let deviceCommand = DeviceStateCommand(userUUID: roomPlayInfo.rtmUID,
                                                       camera: userStatus.camera,
                                                       mic: userStatus.mic)
                do {
                    try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
                }
                catch {
                    print("send device status error \(error)")
                }
            }
            currentUsers[roomPlayInfo.rtmUID]?.status = userStatus
        }
    }
    
    // RtmUUID: user
    lazy var currentUsers: [String: RoomUser] = [roomPlayInfo.rtmUID: RoomUser(rtmUUID: roomPlayInfo.rtmUID,
                                                                               rtcUID: roomPlayInfo.rtcUID,
                                                                               name: roomPlayInfo.userInfo?.name ?? "",
                                                                               avatarURL: roomPlayInfo.userInfo?.avatar,
                                                                               status: userStatus)] {
        didSet {
            updateUIWith(users: currentUsers.map { $0.value})
        }
    }
    
    // Members in the classroom or did send message
    // RtmUUID : user
    lazy var cachedUsers: [String: RoomUser] = currentUsers {
        didSet {
            chatViewController.tableView.reloadData()
        }
    }
    
    var isTeacher: Bool {
        roomPlayInfo.rtmUID == roomPlayInfo.ownerUUID
    }
    
    // MARK: - LifeCycle
    init(roomPlayInfo: RoomPlayInfo,
         roomInfo: RoomInfo,
         cameraOn: Bool,
         micOn: Bool) {
        self.roomInfo = roomInfo
        self.roomPlayInfo = roomPlayInfo
        self.userStatus = .init(isSpeak: false, isRaisingHand: false, camera: cameraOn, mic: micOn)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        connectServices()
    }
    
    // MARK: - Action
    @objc func onClickSetting(_ sender: UIButton) {
        sender.isSelected = true
        settingViewController.cameraOn = userStatus.camera
        settingViewController.micOn = userStatus.mic
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
        popoverViewController(viewController: inviteController, fromSource: sender)
    }
    
    @objc func onClickUsers(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        popoverViewController(viewController: usersViewController, fromSource: sender)
    }
    
    @objc func onClickRaiseHand(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        userStatus.isRaisingHand = !userStatus.isRaisingHand
    }
    
    @objc func onClickStart() {
        let req = RoomStatusUpdateRequest(newStatus: .Started, roomUUID: roomPlayInfo.roomUUID)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                return
            case .failure(let error):
                print("start api", error)
            }
        }
        do {
            if !userStatus.mic {
                userStatus.mic = true
            }
            try rtm.sendCommand(.roomStartStatus(.Started), toTargetUID: nil)
            roomStatus?.roomStartStatus = .Started
            try rtm.sendCommand(.classRoomMode(.lecture), toTargetUID: nil)
            roomStatus?.classRoomType = .lecture
        }
        catch {
            print("room start error \(error)")
        }
    }
    
    @objc func onClickPause() {
        let req = RoomStatusUpdateRequest(newStatus: .Paused, roomUUID: roomPlayInfo.roomUUID)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                return
            case .failure(let error):
                print("pause api", error)
            }
        }
        do {
            if userStatus.mic {
                userStatus.mic = false
            }
            try rtm.sendCommand(.roomStartStatus(.Paused), toTargetUID: nil)
            roomStatus?.roomStartStatus = .Paused
        }
        catch {
            print("room pause error \(error)")
        }
    }
    
    @objc func onClickResume() {
        onClickStart()
    }
    
    @objc func onClickStop() {
        func performAction() {
            let req = RoomStatusUpdateRequest(newStatus: .Stopped, roomUUID: roomPlayInfo.roomUUID)
            ApiProvider.shared.request(fromApi: req) { result in
                switch result {
                case .success:
                    return
                case .failure(let error):
                    print("end api", error)
                }
            }
            do {
                try rtm.sendCommand(.roomStartStatus(.Stopped), toTargetUID: nil)
                roomStatus?.roomStartStatus = .Stopped
            }
            catch {
                print("room stop error \(error)")
            }
        }
        
        showCheckAlert(title: "确认结束上课?", message: "一旦结束上课，所有用户退出房间，并且自动结束课程和录制（如有），不能继续直播") {
            performAction()
        }
    }
    
    // MARK: - Private
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
    
    func updateUIWith(users: [RoomUser]) {
        // TODO: throllte , update UI
        let containsTeach = users.contains(where: { $0.rtmUUID == roomPlayInfo.ownerUUID })
        rtcViewController.shouldShowNoTeach = !containsTeach
        rtcViewController.users = users
        usersViewController.users = users
    }
    
    func setupToolbar() {
        view.addSubview(rightToolBar)
        rightToolBar.snp.makeConstraints { make in
            // 看下这里的效果
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
    
    // When there is no user in the class room, init the status
    func initRoomStatusWithNoUser() {
        setupToolbar()
        switch roomInfo.roomType {
        case .bigClass:
            roomStatus = .init(banMessage: false, roomStartStatus: roomInfo.roomStatus, classRoomType: .interaction)
        case .smallClass:
            roomStatus = .init(banMessage: false, roomStartStatus: roomInfo.roomStatus, classRoomType: .interaction)
        case .oneToOne:
            roomStatus = .init(banMessage: false, roomStartStatus: roomInfo.roomStatus, classRoomType: .interaction)
        default:
            roomStatus = .init(banMessage: false, roomStartStatus: roomInfo.roomStatus, classRoomType: .interaction)
        }
        updateUIWith(users: currentUsers.map { $0.value })
    }
    
    func initRoomStatusFromOthersCommand(_ command: ChannelStatusCommand) {
        setupToolbar()
        roomStatus = .init(banMessage: command.banMessage,
                           roomStartStatus: command.roomStartStatus,
                           classRoomType: command.classRoomMode)
        for (uid, statusStr) in command.userStates {
            let newStatus = RoomUserStatus(string: statusStr)
            self.currentUsers[uid]?.status = newStatus
        }
        // Fill all the user status with default value
        let values = currentUsers.filter({ $0.value.status == nil }).map { (key, value) -> (String, RoomUser) in
            var newUser = value
            newUser.status = .init(isSpeak: false, isRaisingHand: false, camera: false, mic: false)
            return (key, newUser)
        }
        currentUsers.merge(values) { u1, u2 in
            if u1.status == nil {
                return u2
            } else {
                return u1
            }
        }
    }
    
    func updateViewsWithRoomStatus(_ status: RoomStatus?) {
        guard let status = status else {
            whiteBoardViewController.toolStackView.isHidden = true
            return
        }
        // Chat message
        if isTeacher {
            chatViewController.banTextButton.isSelected = status.banMessage
            chatViewController.isMessageBaned = false
        } else {
            chatViewController.isMessageBaned = status.banMessage
        }

        if isTeacher {
            // Teacher tool bar
            teacherOperationStackView.arrangedSubviews.forEach({
                $0.removeFromSuperview()
                teacherOperationStackView.removeArrangedSubview($0)
            })
            switch status.roomStartStatus {
            case .Idle:
                teacherOperationStackView.addArrangedSubview(startButton)
            case .Paused:
                teacherOperationStackView.addArrangedSubview(resumeButton)
                teacherOperationStackView.addArrangedSubview(endButton)
            case .Started:
                teacherOperationStackView.addArrangedSubview(pauseButton)
                teacherOperationStackView.addArrangedSubview(endButton)
            default:
                break
            }
        } else {
            // TODO: Rtc mute, chat room, whiteboard
            updateInteractionEnable(status.classRoomType == .interaction)
        }
    }
    
    func updateInteractionEnable(_ enable: Bool) {
        raiseHandButton.isSelected = userStatus.isRaisingHand
        raiseHandButton.isHidden = enable
        whiteBoardViewController.toolStackView.isHidden = !enable
        whiteBoardViewController.room.setWritable(enable, completionHandler: nil)
    }
    
    // TODO: responde is not reliable
    func respondToReqeustChannelStatusCommand(_ command: RequestChannelStatusCommand, fromUID uid: String) {
        // Append user to the user list
        appendUsersWith([uid], isCurrentInTheClassRoom: true) { result in
            switch result {
            case .success:
                var userStates: [String: String] = [:]
                for (key, value) in self.currentUsers {
                    userStates[key] = value.status?.toString() ?? ""
                }
                // When new user come in, is not raising hand
                self.currentUsers[uid]?.status = RoomUserStatus(isSpeak: command.user.isSpeak, isRaisingHand: false, camera: command.user.camera, mic: command.user.mic)
                // Responde channel status when userUUID list contains self
                guard command.userUUIDs.contains(self.roomPlayInfo.rtmUID) else { return }
                // Generate the response
                let statusCommands = ChannelStatusCommand(banMessage: self.roomStatus?.banMessage ?? false,
                                                          roomStartStatus: self.roomStatus?.roomStartStatus ?? .Idle,
                                                          classRoomMode: self.roomStatus?.classRoomType ?? .interaction,
                                                          userStates: userStates)
                do {
                    try self.rtm.sendCommand(.channelStatus(statusCommands), toTargetUID: uid)
                }
                catch {
                    print("send channel status error \(error)")
                }
            case .failure(let error):
                print("fetch user info error when respond to command, \(error)")
            }
        }
    }
    
    func processAfterJoinChannelSuccess() {
        rtm.requestHistory(channelId: roomPlayInfo.roomUUID) { result in
            switch result {
            case .success(let messages):
                self.chatViewController.messages.append(contentsOf: messages)
            case .failure(let erorr):
                return
            }
        }
        rtm.channel?.getMembersWithCompletion({ [weak self] members, error in
            guard let self = self else { return }
            guard error == .ok else {
                print("fetch members error \(error.rawValue)")
                return
            }
            guard let ids = members?.map({ $0.userId }),
                  let randomId = ids.filter({ $0 != self.roomPlayInfo.rtmUID }).randomElement() else {
                      print("class room is emtpy")
                      self.initRoomStatusWithNoUser()
                      return
                  }
            self.appendUsersWith(ids, isCurrentInTheClassRoom: true) { result in
                switch result {
                case .success:
                    let status = self.userStatus
                    let request = RequestChannelStatusCommand(roomUUID: self.roomPlayInfo.roomUUID,
                                                              userUUIDs: [randomId],
                                                              user: .init(name: self.roomPlayInfo.userInfo?.name ?? "",
                                                                          camera: status.camera,
                                                                          mic: status.mic,
                                                                          isSpeak: status.isSpeak))
                    do {
                        try self.rtm.sendCommand(.requestChannelStatus(request), toTargetUID: nil)
                    }
                    catch {
                        print("send request channel status error \(error)")
                    }
                case .failure(let error):
                    print("get member detail info error \(error)")
                }
            }
        })
    }
    
    func connectServices() {
        navigationController?.showActivityIndicator()
        let group = DispatchGroup()
        
        group.enter()
        whiteBoardViewController.joinRoom { [weak self] error in
            defer {
                group.leave()
            }
            if let error = error {
                self?.leaveWithAlertMessage(error.localizedDescription)
                return
            }
        }
        
        group.enter()
        rtm.joinChannel { [weak self] joinError in
            defer {
                group.leave()
            }
            guard let self = self else { return }
            if let joinError = joinError {
                print("join channel error \(joinError)")
                self.leaveWithAlertMessage(joinError.localizedDescription)
                return
            } else {
                print("join channel success")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.rtcViewController.joinChannel()
            self?.processAfterJoinChannelSuccess()
            self?.navigationController?.stopActivityIndicator()
        }
    }
    
    func leaveWithAlertMessage(_ msg: String? = nil) {
        func disconnectServices() {
            whiteBoardViewController.leave()
            rtcViewController.leave()
            rtm.leave()
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
    
    // Update users with no status. Status should be updated by command
    func appendUsersWith(_ ids: [String], isCurrentInTheClassRoom: Bool, completion: @escaping ((Result<Void, Error>)->Void)) {
        ApiProvider.shared.request(fromApi: MemberRequest(roomUUID: roomPlayInfo.roomUUID, usersUUID: ids)) { result in
            switch result {
            case .failure(let error):
                print("query member error \(ids), \(error)")
                completion(.failure(error))
            case .success(let value):
                let array = value.response.map {
                    ($0.key, RoomUser(rtmUUID: $0.key,
                                      rtcUID: $0.value.rtcUID,
                                      name: $0.value.name,
                                      avatarURL: $0.value.avatarURL,
                                      status: nil))
                }
                let dic = Dictionary(uniqueKeysWithValues: array)
                self.cachedUsers.merge(dic, uniquingKeysWith: { a, b in
                    if a.status == nil { return b }
                    return a
                })
                if isCurrentInTheClassRoom {
                    self.currentUsers.merge(dic, uniquingKeysWith: { a, b in
                        if a.status == nil { return b }
                        return a
                    })
                }
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Lazy
    lazy var whiteBoardViewController: WhiteboardViewController = {
        let vc = WhiteboardViewController(roomPlayInfo:  roomPlayInfo)
        vc.delegate = self
        return vc
    }()
    
    lazy var rtcViewController: RtcViewController = {
        let vc = RtcViewController(token: roomPlayInfo.rtcToken,
                                   channelId: roomPlayInfo.roomUUID,
                                   rtcUid: roomPlayInfo.rtcUID)
        vc.users = currentUsers.map { $0.value }
        vc.delegate = self
        return vc
    }()
    
    lazy var rtm: ClassRoomRtm = {
        let rtm = ClassRoomRtm(rtmToken: roomPlayInfo.rtmToken,
                               roomUID: roomPlayInfo.rtmUID,
                               roomUUID: roomPlayInfo.roomUUID)
        rtm.delegate = self
        return rtm
    }()
    
    lazy var inviteController: InviteViewController = {
        let vc = InviteViewController(roomInfo: roomInfo, roomUUID: roomPlayInfo.roomUUID, userName: roomPlayInfo.userInfo?.name ?? "")
        vc.dismissHandler = { [weak self] in
            self?.inviteButton.isSelected = false
            self?.toast("链接已复制到剪贴板")
        }
        return vc
    }()
    
    lazy var usersViewController: ClassRoomUsersViewController = {
        let vc = ClassRoomUsersViewController()
        vc.dismissHandler = { [weak self] in
            self?.usersButton.isSelected = false
        }
        vc.roomOwnerRtmUUID = roomPlayInfo.ownerUUID
        vc.users = currentUsers.map { $0.value }
        vc.delegate = self
        return vc
    }()
    
    lazy var settingViewController: ClassRoomSettingViewController = {
        let vc = ClassRoomSettingViewController(cameraOn: userStatus.camera, micOn: userStatus.mic, videoAreaOn: !rtcViewController.view.isHidden)
        vc.dismissHandler = { [weak self] in
            self?.settingButton.isSelected = false
        }
        vc.delegate = self
        return vc
    }()
    
    lazy var chatViewController: ChatViewController = {
        let vc = ChatViewController()
        vc.userRtmId = roomPlayInfo.rtmUID
        vc.delegate = self
        vc.dismissHandler = { [weak self] in
            self?.chatButton.isSelected = false
        }
        return vc
    }()
    
    lazy var chatButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "chat")!)
        button.addTarget(self, action: #selector(onClickChat(_:)), for: .touchUpInside)
        return button
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
        btn.addTarget(self, action: #selector(onClickStart), for: .touchUpInside)
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
        btn.addTarget(self, action: #selector(onClickPause), for: .touchUpInside)
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
        btn.addTarget(self, action: #selector(onClickResume), for: .touchUpInside)
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
        btn.addTarget(self, action: #selector(onClickStop), for: .touchUpInside)
        return btn
    }()
    
    lazy var settingButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "classroom_setting")!)
        button.addTarget(self, action: #selector(onClickSetting(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var raiseHandButton: RaiseHandButton = {
        let button = RaiseHandButton(type: .custom)
        button.addTarget(self, action: #selector(onClickRaiseHand(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var usersButton: UIButton = {
        let button = UIButton.buttonWithClassRoomStyle(withImage: UIImage(named: "users")!)
        button.addTarget(self, action: #selector(onClickUsers(_:)), for: .touchUpInside)
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

// MARK: - Whiteboard
extension  ClassRoomViewController: WhiteboardViewControllerDelegate {
    func whiteboadViewController(_ controller: WhiteboardViewController, error: Error) {
        return
    }
    
    func whiteboardViewControllerDidUpdatePhase(_ controller: WhiteboardViewController, phase: WhiteRoomPhase) {
        return
    }
}

// MARK: - Rtm
extension ClassRoomViewController: ClassRoomRtmDelegate {
    func classRoomRtm(_ rtm: ClassRoomRtm, error: Error) {
        leaveWithAlertMessage(error.localizedDescription)
    }
    
    func classRoomRtmDidReceiveMessage(_ rtm: ClassRoomRtm, message: UserMessage) {
        chatViewController.messages.append(.user(message))
    }
    
    func classRoomRtmDidReceiveCommand(_ rtm: ClassRoomRtm, command: RtmCommand, senderId: String) {
        print("command \(command)", "sender:",  senderId)
        switch command {
        case .deviceState(let deviceStateCommand):
            // Update data, and update in Rtc
            var newStatus = self.currentUsers[deviceStateCommand.userUUID]?.status
            newStatus?.camera = deviceStateCommand.camera
            newStatus?.mic = deviceStateCommand.mic
            self.currentUsers[deviceStateCommand.userUUID]?.status = newStatus
        case .requestChannelStatus(let requestChannelStatusCommand):
            respondToReqeustChannelStatusCommand(requestChannelStatusCommand, fromUID: senderId)
        case .roomStartStatus(let roomStartStatus):
            self.roomStatus?.roomStartStatus = roomStartStatus
            if roomStartStatus == .Stopped {
                self.showAlertWith(title: "提示", message: "房间已结束，点击退出") {
                    self.leaveWithAlertMessage(nil)
                }
            }
        case .channelStatus(let channelStatusCommand):
            initRoomStatusFromOthersCommand(channelStatusCommand)
        case .raiseHand(let bool):
            currentUsers[senderId]?.status?.isRaisingHand = bool
        case .accpetRaiseHand(let accpetRaiseHandCommand):
            if accpetRaiseHandCommand.userUUID == roomPlayInfo.rtmUID {
                var new = userStatus
                new.mic = true
                new.isSpeak = true
                new.isRaisingHand = false
                userStatus = new
                toast("麦克风打开，你现在可以发言了")
                // UI
                raiseHandButton.isSelected = false
                raiseHandButton.isHidden = true
                updateInteractionEnable(true)
            } else {
                if let user = currentUsers.first(where: { $0.key == accpetRaiseHandCommand.userUUID }) {
                    var new = user.value
                    new.status?.mic = true
                    new.status?.isSpeak = true
                    new.status?.isRaisingHand = false
                    currentUsers[user.key] = new
                }
            }
        case .cancelRaiseHand(_):
            if userStatus.isRaisingHand {
                userStatus.isRaisingHand = false
                raiseHandButton.isSelected = false
                raiseHandButton.isHidden = false
            }
        case .banText(let bool):
            chatViewController.messages.append(.notice(bool ? "已禁言" : "已解除禁言"))
            roomStatus?.banMessage = bool
        case .speak(let array):
            for user in array {
                if user.userUUID == roomPlayInfo.rtmUID {
                    var new = userStatus
                    new.isSpeak = user.speak
                    new.mic = user.speak
                    userStatus = new
                    toast(user.speak ? "发言开始" : "发言被结束")
                    updateInteractionEnable(user.speak)
                } else {
                    var new = currentUsers[user.userUUID]?.status
                    new?.isSpeak = user.speak
                    new?.mic = user.speak
                    currentUsers[user.userUUID]?.status = new
                }
            }
        case .classRoomMode(let classRoomType):
            roomStatus?.classRoomType = classRoomType
        case .notice(let string):
            print("receive rtm command notice \(string)")
            return
        case .undefined(let string):
            print("receive rtm command undefined \(string)")
            return
        }
    }
    
    func classRoomRtmMemberLeft(_ rtm: ClassRoomRtm, memberUserId: String) {
        currentUsers[memberUserId] = nil
    }
    
    func classRoomRtmMemberJoined(_ rtm: ClassRoomRtm, memberUserId: String) {
        return
    }
}

// MARK: - Settings
extension ClassRoomViewController: ClassRoomSettingViewControllerDelegate {
    func classRoomSettingViewControllerDidClickLeave(_ controller: ClassRoomSettingViewController) {
        guard let status = roomStatus?.roomStartStatus else {
            leaveWithAlertMessage(nil)
            return
        }
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
                do {
                    try self.rtm.sendCommand(.roomStartStatus(.Stopped), toTargetUID: nil)
                    self.leaveWithAlertMessage(nil)
                }
                catch {
                    print("finish classroom error, \(error)")
                    self.showAlertWith(title: "error", message: error.localizedDescription, completionHandler: nil)
                }
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
            userStatus.mic = isOn
        case .camera:
            userStatus.camera = isOn
        }
    }
}

// MARK: - Chat
extension ClassRoomViewController: ChatViewControllerDelegate {
    func chatViewControllerDidClickBanMessage(_ controller: ChatViewController) {
        if isTeacher, let ban = roomStatus?.banMessage {
            do {
                try rtm.sendCommand(.banText(!ban), toTargetUID: nil)
                roomStatus?.banMessage = !ban
                chatViewController.messages.append(.notice(!ban ? "已禁言" : "已解除禁言"))
            }
            catch {
                print("ban message error \(error)")
            }
            
        }
    }
    
    func chatViewControllerDidSendMessage(_ controller: ChatViewController, message: String) {
        rtm.sendMessage(message)
    }
    
    func chatViewControllerNeedNickNameForUserId(_ controller: ChatViewController, userId: String) -> String? {
        if let name = cachedUsers[userId]?.name {
            return name
        } else {
            appendUsersWith([userId], isCurrentInTheClassRoom: false) { _ in
                
            }
            return ""
        }
    }
}

// MARK: - Rtc
extension ClassRoomViewController: RtcViewControllerDelegate {
    func rtcViewControllerDidClickMic(_ controller: RtcViewController, forUser user: RoomUser) {
        if user.rtmUUID == roomPlayInfo.rtmUID {
            userStatus.mic = !userStatus.mic
        } else {
            // Can't update other's device state
        }
    }
    
    func rtcViewControllerDidClickCamera(_ controller: RtcViewController, forUser user: RoomUser) {
        if user.rtmUUID == roomPlayInfo.rtmUID {
            userStatus.camera = !userStatus.camera
        } else {
            // Can't update other's device state
        }
    }
    
    func rtcViewControllerDidMeetError(_ controller: RtcViewController, error: Error) {
        // TODO: Update Rtc with error
    }
}

// MARK: - Users List
extension ClassRoomViewController: ClassRoomUsersViewControllerDelegate {
    func classRoomUsersViewControllerDidClickRaiseHand(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        guard isTeacher else { return }
        do {
            try rtm.sendCommand(.accpetRaiseHand(.init(userUUID: user.rtmUUID, accept: true)), toTargetUID: nil)
            var new = currentUsers[user.rtmUUID]?.status
            new?.isRaisingHand = false
            new?.isSpeak = true
            currentUsers[user.rtmUUID]?.status = new
        }
        catch {
            print("accpet raise hand error \(error)")
        }
    }
    
    func classRoomUsersViewControllerDidClickDisConnect(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        func sendCommand() {
            do {
                try rtm.sendCommand(.speak([.init(userUUID: user.rtmUUID, speak: false)]), toTargetUID: nil)
            }
            catch {
                print("cancel speak fail \(error)")
            }
        }
        if isTeacher {
            sendCommand()
            var new = currentUsers[user.rtmUUID]?.status
            new?.isSpeak = false
            new?.mic = false
            currentUsers[user.rtmUUID]?.status = new
        } else if user.rtmUUID == roomPlayInfo.rtmUID {
            sendCommand()
            var new = userStatus
            new.isSpeak = false
            new.mic = false
            userStatus = new
        }
    }
    
    func classRoomUsersViewControllerDidClickMic(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        if user.rtmUUID == roomPlayInfo.rtmUID {
            userStatus.mic = !userStatus.mic
        } else if isTeacher, let status = user.status, status.mic {
            do {
                let deviceCommand = DeviceStateCommand(userUUID: user.rtmUUID,
                                                       camera: status.camera,
                                                       mic: false)
                try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
                currentUsers[user.rtmUUID]?.status?.mic = false
            }
            catch {
                print("close user mic error \(error)")
            }
        } else {
            toast("无法操作")
        }
    }
    
    func classRoomUsersViewControllerDidClickCamera(_ vc: ClassRoomUsersViewController, user: RoomUser) {
        if user.rtmUUID == roomPlayInfo.rtmUID {
            userStatus.camera = !userStatus.camera
        } else if isTeacher, let status = user.status, status.camera {
            do {
                let deviceCommand = DeviceStateCommand(userUUID: user.rtmUUID,
                                                       camera: false,
                                                       mic: status.mic)
                try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
                currentUsers[user.rtmUUID]?.status?.camera = false
            }
            catch {
                print("close user mic error \(error)")
            }
        } else {
            toast("无法操作")
        }
    }
    
    
}
