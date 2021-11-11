//
//  ClassRoomViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/8.
//  Copyright © 2021 agora.io. All rights reserved.
//


import RxSwift
import RxRelay
import RxCocoa

class ClassRoomViewModel {
    let classRoom: ClassRoom
    let rtm: ClassRoomRtm
    
    // ex. User raise hand
    let unprocessUserSignal: PublishRelay<Bool> = .init()
    let receiveMessageSignal: PublishRelay<Message> = .init()
    let erroSignal: PublishRelay<Error?> = .init()
    let stopClasssAlert = PublishRelay<()->Void>.init()
    let cachedUserName: BehaviorRelay<[String: String]> = .init(value: [:])
    
    fileprivate var roomStatusSubscribe: ((CompletableEvent) -> Void)?
    
    init(classRoom: ClassRoom,
         rtm: ClassRoomRtm) {
        self.classRoom = classRoom
        self.rtm = rtm
        self.rtm.delegate = self
    }
    
    // MARK: - Action
    @objc func onClickStart() {
        let req = RoomStatusUpdateRequest(newStatus: .Started, roomUUID: classRoom.roomUUID)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                return
            case .failure(let error):
                print("start api", error)
            }
        }
        do {
            if !classRoom.userStatus.mic {
                onClickUserMic()
            }
            try rtm.sendCommand(.roomStartStatus(.Started), toTargetUID: nil)
            classRoom.status.accept(.Started)
            try rtm.sendCommand(.classRoomMode(.lecture), toTargetUID: nil)
            classRoom.mode.accept(.lecture)
        }
        catch {
            print("room start error \(error)")
        }
    }
    
    @objc func onClickPause() {
        let req = RoomStatusUpdateRequest(newStatus: .Paused, roomUUID: classRoom.roomUUID)
        ApiProvider.shared.request(fromApi: req) { result in
            switch result {
            case .success:
                return
            case .failure(let error):
                print("pause api", error)
            }
        }
        do {
            if classRoom.userStatus.mic {
                onClickUserMic()
            }
            try rtm.sendCommand(.roomStartStatus(.Paused), toTargetUID: nil)
            classRoom.status.accept(.Paused)
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
            let req = RoomStatusUpdateRequest(newStatus: .Stopped, roomUUID: classRoom.roomUUID)
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
                classRoom.status.accept(.Stopped)
            }
            catch {
                print("room stop error \(error)")
            }
        }
        stopClasssAlert.accept({
            performAction()
        })
    }
    
    func onClickUserMic() {
        var new = classRoom.userStatus
        new.mic = !new.mic
        
        let deviceCommand = DeviceStateCommand(userUUID: classRoom.userUUID,
                                               camera: new.camera,
                                               mic: new.mic)
        do {
            try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
            classRoom.updateUserStatus(new)
        }
        catch {
            print("send device status error \(error)")
        }
    }
    
    func onClickUserCamera() {
        var new = classRoom.userStatus
        new.camera = !new.camera
        
        let deviceCommand = DeviceStateCommand(userUUID: classRoom.userUUID,
                                               camera: new.camera,
                                               mic: new.mic)
        do {
            try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
            classRoom.updateUserStatus(new)
        }
        catch {
            print("send device status error \(error)")
        }
    }
    
    @objc func onClickRaiseHand() {
        do {
            var new = classRoom.userStatus
            new.isRaisingHand = !new.isRaisingHand
            try rtm.sendCommand(.raiseHand(new.isRaisingHand), toTargetUID: nil)
            classRoom.updateUserStatus(new)
        }
        catch {
            print("raise hand error \(error)")
        }
    }
    
    func onClickUserMic(userRtmUUID: String) {
        if let index = classRoom.users.value.firstIndex(where: { $0.rtmUUID == userRtmUUID }) {
            let user = classRoom.users.value[index]
            if user.rtmUUID == classRoom.userUUID {
                onClickUserMic()
            } else {
                var status = user.status
                if status.mic {
                    status.mic = false
                    let deviceCommand = DeviceStateCommand(userUUID: userRtmUUID,
                                                           camera: status.camera,
                                                           mic: false)
                    do {
                        try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
                        classRoom.updateUserStatusFor(userRtmUID: userRtmUUID, status: status)
                    }
                    catch {
                        print("update user mic error", error)
                    }
                }
            }
        }
    }
    
    func onClickUserCamera(userRtmUUID: String) {
        if let index = classRoom.users.value.firstIndex(where: { $0.rtmUUID == userRtmUUID }) {
            let user = classRoom.users.value[index]
            if user.rtmUUID == classRoom.userUUID {
                onClickUserCamera()
            } else {
                var status = user.status
                if status.camera {
                    status.camera = false
                    let deviceCommand = DeviceStateCommand(userUUID: userRtmUUID,
                                                           camera: false,
                                                           mic: status.mic)
                    do {
                        try rtm.sendCommand(.deviceState(deviceCommand), toTargetUID: nil)
                        classRoom.updateUserStatusFor(userRtmUID: userRtmUUID, status: status)
                    }
                    catch {
                        print("update user camera error", error)
                    }
                }
            }
        }
    }
    
    func onClickBanMessage() {
        guard classRoom.isTeacher else { return }
        let ban = !classRoom.messageBan.value
        do {
            try rtm.sendCommand(.banText(ban), toTargetUID: nil)
            classRoom.messageBan.accept(ban)
        }
        catch {
            print("ban message error \(error)")
        }
    }
    
    func onClickDisconnect(user: RoomUser) {
        func sendCommand() throws {
            try rtm.sendCommand(.speak([.init(userUUID: user.rtmUUID, speak: false)]), toTargetUID: nil)
        }
        guard var status = classRoom.users.value.first(where: { $0.rtmUUID == user.rtmUUID })?.status else { return }
        do {
            try sendCommand()
            status.isSpeak = false
            status.mic = false
            status.camera = false
            classRoom.updateUserStatusFor(userRtmUID: user.rtmUUID, status: status)
        }
        catch {
            print("cancel speak fail \(error)")
        }
    }
    
    func onClickStopInteracting() {
        guard classRoom.isTeacher else { return }
        let users = classRoom.users.value
        let speakingUsers = users.filter{ $0.status.isSpeak }
        let raisingHandUsers = users.filter{ $0.status.isRaisingHand }
        do  {
            if !raisingHandUsers.isEmpty {
                try rtm.sendCommand(.cancelRaiseHand(true), toTargetUID: nil)
            }
            if !speakingUsers.isEmpty {
                let commands = speakingUsers.map { SpeakCommand.init(userUUID: $0.rtmUUID, speak: false)}
                try rtm.sendCommand(.speak(commands), toTargetUID: nil)
            }
            var users: [RoomUser] = .init(raisingHandUsers)
            users.append(contentsOf: speakingUsers)
            users = users.removeDuplicate()
            if !users.isEmpty {
                for user in users {
                    var status = user.status
                    status.isSpeak = false
                    status.isRaisingHand = false
                    classRoom.updateUserStatusFor(userRtmUID: user.rtmUUID, status: status)
                }
            }
        }
        catch {
            print("stop interacting fail \(error)")
        }
    }
    
    func onClickRaisedHandFor(user: RoomUser) {
        guard classRoom.isTeacher else { return }
        do {
            try rtm.sendCommand(.accpetRaiseHand(.init(userUUID: user.rtmUUID, accept: true)), toTargetUID: nil)
            if var new = classRoom.users.value.first(where: { $0.rtmUUID == user.rtmUUID})?.status {
                new.isRaisingHand = false
                new.isSpeak = true
                new.mic = true
                classRoom.updateUserStatusFor(userRtmUID: user.rtmUUID, status: new)
            }
        }
        catch {
            print("accpet raise hand error \(error)")
        }
    }
    
    
    // MARK: - Public
    func join() -> Completable {
        return .create { [weak self] s in
            self?.rtm.joinChannel { error in
                if let error = error {
                    s(.error(error))
                    return
                }
                s(.completed)
            }
            return Disposables.create()
        }
    }
    
    func requestHistory() -> Single<[Message]> {
        return Single<[Message]>.create { [weak self] s in
            guard let self = self else {
                return Disposables.create()
            }
            self.rtm.requestHistory(channelId: self.rtm.roomUUID) { result in
                switch result {
                case .failure(let error):
                    s(.failure(error))
                    print(error)
                    return
                case .success(let history):
                    let noNameIds = history.filter({
                        if case .user(let msg) = $0 {
                            return self.cachedUserName.value[msg.userId] == nil
                        }
                        return false
                    }).map { item -> String in
                        if case .user(let msg) = item {
                            return msg.userId
                        }
                        return ""
                    }.removeDuplicate()
                    guard !noNameIds.isEmpty else {
                        s(.success(history))
                        return
                    }
                    self.requestUsersFrom(ids: noNameIds) { result in
                        switch result {
                        case .success(let users):
                            var new = self.cachedUserName.value
                            new.merge(users.map { ($0.rtmUUID, $0.name) }, uniquingKeysWith: { i, j in return i })
                            self.cachedUserName.accept(new)
                            s(.success(history))
                        case .failure(let error):
                            s(.failure(error))
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    func sendMessage(_ message: String) {
        rtm.sendMessage(message)
    }
    
    func requestRoomStatus() -> Completable {
        return Completable.create { [weak self] s in
            guard let self = self else { return Disposables.create() }
            self.rtm.channel?.getMembersWithCompletion({ [weak self] members, error in
                guard let self = self else { return }
                guard error == .ok else {
                    s(.error(String(error.rawValue)))
                    print("fetch members error \(error.rawValue)")
                    return
                }
                guard let ids = members?.map({ $0.userId }),
                      let randomId = ids.filter({ $0 != self.rtm.userUID }).randomElement() else {
                          print("class room is emtpy")
                          self.classRoom.applyWithNoUser()
                          s(.completed)
                          return
                      }
                self.requestUsersFrom(ids: ids) { result in
                    switch result {
                    case .success(let users):
                        self.classRoom.appendUser(fromContentsOf: users)
                        // Cache name
                        var vs: [String: String] = [:]
                        for user in users {
                            vs[user.rtmUUID] = user.name
                        }
                        vs.merge(self.cachedUserName.value, uniquingKeysWith: { i, j in
                            return i
                        })
                        self.cachedUserName.accept(vs)
                        // FIX: send a unreliable status to others here
                        // Send reqeust to others
                        let status = self.classRoom.userStatus
                        let request = RequestChannelStatusCommand(roomUUID: self.rtm.roomUUID,
                                                                  userUUIDs: [randomId],
                                                                  user: .init(name: self.classRoom.userName,
                                                                              camera: status.camera,
                                                                              mic: status.mic,
                                                                              isSpeak: status.isSpeak))
                        do {
                            try self.rtm.sendCommand(.requestChannelStatus(request), toTargetUID: nil)
                        }
                        catch {
                            print("send request channel status error \(error)")
                            s(.error(error))
                        }
                        // Wait until status request, see 'roomStatusRequest'
                        self.roomStatusSubscribe = s
                    case .failure(let error):
                        s(.error(error))
                    }
                }
            })
            return Disposables.create()
        }
    }
    
    func leave() {
        rtm.leave()
    }
    
    func endClass() {
        guard classRoom.isTeacher else { return }
        do {
            try self.rtm.sendCommand(.roomStartStatus(.Stopped), toTargetUID: nil)
        }
        catch {
            print("finish classroom error, \(error)")
        }
    }
    
    func requestNickNameFor(userId: String) -> String? {
        if let name = cachedUserName.value[userId] {
            return name
        } else {
            requestUsersFrom(ids: [userId]) { result in
                switch result {
                case.failure(let error):
                    print("user name request error", error.localizedDescription)
                case .success(let users):
                    if let user = users.first {
                        var new = self.cachedUserName.value
                        new[user.rtmUUID] = user.name
                        self.cachedUserName.accept(new)
                    }
                }
            }
            return nil
        }
    }
    
    // MARK: - Private
    /// Request Users with no detemined status
    func requestUsersFrom(ids: [String], completion: @escaping ((Result<[RoomUser], Error>)->Void)) {
        ApiProvider.shared.request(fromApi: MemberRequest(roomUUID: rtm.roomUUID, usersUUID: ids)) { result in
            switch result {
            case .failure(let error):
                print("query member error \(ids), \(error)")
                completion(.failure(error))
            case .success(let value):
                let users = value.response.map {
                    return RoomUser(rtmUUID: $0.key,
                             rtcUID: $0.value.rtcUID,
                             name: $0.value.name,
                             avatarURL: $0.value.avatarURL)
                }
                completion(.success(users))
            }
        }
    }
    
    // TODO: response is not reliable, should depend on the current status
    func respondToReqeustChannelStatusCommand(_ command: RequestChannelStatusCommand, fromUID uid: String) {
        // Append user to the user list
        requestUsersFrom(ids: [uid]) { result in
            switch result {
            case .success(let users):
                if let userInfo = users.first {
                    // When new user come in, is not raising hand
                    let userStatus = RoomUserStatus(isSpeak: command.user.isSpeak,
                                                    isRaisingHand: false,
                                                    camera: command.user.camera, mic: command.user.mic)
                    let newUser = RoomUser(rtmUUID: uid,
                                           rtcUID: userInfo.rtcUID,
                                           name: userInfo.name,
                                           avatarURL: userInfo.avatarURL,
                                           status: userStatus)
                    self.classRoom.appendUser(newUser)
                    var newCache = self.cachedUserName.value
                    newCache[newUser.rtmUUID] = newUser.name
                    self.cachedUserName.accept(newCache)
                }
                // Respond channel status when userUUID list contains self
                guard command.userUUIDs.contains(self.classRoom.userUUID) else { return }
                // Send the recent user list to the new comming
                var userStates: [String: String] = [:]
                for user in self.classRoom.users.value {
                    let uuid = user.rtmUUID
                    let statusString = user.status.toString()
                    userStates[uuid] = statusString
                }
                // Generate the response
                let statusCommands = ChannelStatusCommand(banMessage: self.classRoom.messageBan.value,
                                                          roomStartStatus: self.classRoom.status.value,
                                                          classRoomMode: self.classRoom.mode.value,
                                                          userStates: userStates)
                do {
                    try self.rtm.sendCommand(.channelStatus(statusCommands), toTargetUID: uid)
                }
                catch {
                    print("send channel status error \(error)")
                }
            case .failure(let error):
                print("append user when new come fail \(error)")
            }
        }
    }
}

extension ClassRoomViewModel: ClassRoomRtmDelegate {
    func classRoomRtm(_ rtm: ClassRoomRtm, error: Error) {
        erroSignal.accept(error)
    }
    
    func classRoomRtmDidReceiveMessage(_ rtm: ClassRoomRtm, message: UserMessage) {
        receiveMessageSignal.accept(.user(message))
    }
    
    func classRoomRtmDidReceiveCommand(_ rtm: ClassRoomRtm, command: RtmCommand, senderId: String) {
        print("command \(command)", "sender:",  senderId)
        switch command {
        case .deviceState(let deviceStateCommand):
            guard var new = classRoom.userStatusFor(userUUID: deviceStateCommand.userUUID) else {
                print("update a user device not exist")
                return
            }
            new.camera = deviceStateCommand.camera
            new.mic = deviceStateCommand.mic
            classRoom.updateUserStatusFor(userRtmUID: deviceStateCommand.userUUID, status: new)
        case .requestChannelStatus(let reqeust):
            respondToReqeustChannelStatusCommand(reqeust, fromUID: senderId)
        case .roomStartStatus(let roomStartStatus):
            classRoom.status.accept(roomStartStatus)
        case .channelStatus(let channelStatusCommand):
            classRoom.messageBan.accept(channelStatusCommand.banMessage)
            classRoom.status.accept(channelStatusCommand.roomStartStatus)
            classRoom.mode.accept(channelStatusCommand.classRoomMode)
            var new = classRoom.users.value
            for (uid, statusStr) in channelStatusCommand.userStates {
                let newStatus = RoomUserStatus(string: statusStr)
                if let index = new.firstIndex(where: { $0.rtmUUID == uid }) {
                    new[index].status = newStatus
                }
            }
            classRoom.users.accept(new)
            roomStatusSubscribe?(.completed)
            roomStatusSubscribe = nil
        case .raiseHand(let raieHand):
            if var newStatus = classRoom.userStatusFor(userUUID: senderId) {
                newStatus.isRaisingHand = raieHand
                classRoom.updateUserStatusFor(userRtmUID: senderId, status: newStatus)
                unprocessUserSignal.accept(true)
            }
        case .accpetRaiseHand(let command):
            if var newStatus = classRoom.userStatusFor(userUUID: command.userUUID) {
                newStatus.isRaisingHand = false
                newStatus.mic = true
                newStatus.isSpeak = true
                classRoom.updateUserStatusFor(userRtmUID: command.userUUID, status: newStatus)
                // TODO: ensure all accept
                unprocessUserSignal.accept(false)
            }
        case .cancelRaiseHand(_):
            let new = classRoom.users.value
                .map { user -> RoomUser in
                    var new = user
                    new.status.isRaisingHand = false
                    return new
                }
            classRoom.users.accept(new)
            unprocessUserSignal.accept(false)
        case .banText(let ban):
            classRoom.messageBan.accept(ban)
        case .speak(let commands):
            for command in commands {
                if var status = classRoom.userStatusFor(userUUID: command.userUUID) {
                    status.isSpeak = false
                    status.mic = false
                    status.camera = false
                    classRoom.updateUserStatusFor(userRtmUID: command.userUUID, status: status)
                }
            }
        case .classRoomMode(let mode):
            classRoom.mode.accept(mode)
        case .notice(let string):
            print("receive rtm command notice \(string)")
            return
        case .undefined(let string):
            print("receive rtm command undefined \(string)")
            return
        }
    }
    
    func classRoomRtmMemberLeft(_ rtm: ClassRoomRtm, memberUserId: String) {
        var new = classRoom.users.value
        if let index = new.firstIndex(where: { $0.rtmUUID == memberUserId }) {
            new.remove(at: index)
            classRoom.users.accept(new)
        }
    }
    
    func classRoomRtmMemberJoined(_ rtm: ClassRoomRtm, memberUserId: String) {
        return
    }
}
