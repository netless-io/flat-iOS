//
//  ClassRoomRtm2.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/10.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import AgoraRtmKit
import RxSwift
import RxCocoa

class ClassRoomRtm2: NSObject {
    fileprivate var agoraKit: AgoraRtmKit!
    fileprivate var messageChannel: AgoraRtmChannel!
    fileprivate var commandChannel: AgoraRtmChannel!
    
    fileprivate let rtmToken: String
    fileprivate let rtmUserUUID: String
    fileprivate let channelId: String
    fileprivate let commandChannelId: String
    
    fileprivate lazy var commandDecoder = CommandDecoder()
    fileprivate lazy var commandEncoder = CommandEncoder()
    
    let error: PublishSubject<Error> = .init()
    let commandPublish: PublishSubject<(senderId: String, RtmCommand)> = .init()
    let newMemberPublish: PublishSubject<String> = .init()
    let memberLeftPublish: PublishSubject<String> = .init()
    let newMessagePublish: PublishSubject<Message> = .init()
    
    init(rtmToken: String,
         rtmUserUUID: String,
         roomUUID: String,
         agoraAppId: String) {
        self.rtmToken = rtmToken
        self.rtmUserUUID = rtmUserUUID
        self.channelId = roomUUID
        self.commandChannelId = roomUUID + "commands"
        super.init()
        agoraKit = AgoraRtmKit(appId: agoraAppId, delegate: self)!
        messageChannel = agoraKit.createChannel(withId: channelId, delegate: self)
        commandChannel = agoraKit.createChannel(withId: commandChannelId, delegate: self)
        agoraGenerator.agoraToken = rtmToken
        agoraGenerator.agoraUserId = rtmUserUUID
    }
    
    func requestHistory() -> Single<[Message]> {
        let channelId = self.channelId
        return .create { observer in
            let endTime = Date()
            let startTime = Date(timeInterval: -(3600 * 24), since: endTime)
            let request = HistoryMessageSourceRequest(filter: .init(destination: channelId,
                                                                    startTime: startTime,
                                                                    endTime: endTime),
                                                      offSet: 0)
            ApiProvider.shared.request(fromApi: request) { result in
                switch result {
                case .failure(let error):
                    print("request history source error", error)
                    observer(.failure(error))
                case .success(let value):
                    var path = value.result
                    if path.hasPrefix("~") {
                        path.removeFirst()
                    }
                    ApiProvider.shared.request(fromApi: HistoryMessageRequest(path: path)) { result in
                        switch result {
                        case .success(let historyResult):
                            let historyMessages = historyResult.result.map { UserMessage(userId: $0.sourceUserId, text: $0.message) }.map { Message.user($0) }
                            observer(.success(historyMessages))
                        case .failure(let error):
                            print("request history error", error)
                            observer(.failure(error))
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    func leave() -> Completable {
        return .create { [weak self] observer in
            self?.agoraKit.logout(completion: { error in
                if error == .ok {
                    observer(.completed)
                } else {
                    observer(.error("rtm logout \(error)"))
                }
            })
            return Disposables.create()
        }
    }
    
    func sendCommand(_ command: RtmCommand, toTargetUID targetId: String?) -> Completable {
        return .create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            do {
                if let targetId = targetId {
                    let str = try self.commandEncoder.encode(command, withChannelId: self.commandChannelId)
                    print("start send command \(str), to \(targetId)")
                    self.agoraKit.send(.init(text: str), toPeer: targetId) { error in
                        print("send p2p \(error == .ok), \(error.rawValue)")
                        if error == .ok {
                            observer(.completed)
                        } else {
                            observer(.error("send p2p command fail \(error)"))
                        }
                    }
                } else {
                    let str = try self.commandEncoder.encode(command, withChannelId: nil)
                    print("start send command \(str), to channel")
                    self.commandChannel?.send(.init(text: str)) { error in
                        print("send command \(str), to channel \(error == .errorOk ? "success" : "fail, \(error)")")
                        if error == .errorOk {
                            observer(.completed)
                        } else {
                            observer(.error("send command fail \(error)"))
                        }
                    }
                }
            }
            catch {
                observer(.error(error.localizedDescription))
            }
            return Disposables.create()
        }
    }
    
    func start() -> Completable {
        return login()
            .andThen(joinChannel(messageChannel))
            .andThen(joinChannel(commandChannel))
    }
    
    func joinChannel(_ channel: AgoraRtmChannel) -> Completable {
        .create { [weak channel] observer in
            guard let channel = channel else {
                      observer(.error("self not exist"))
                      return Disposables.create()
                  }
            channel.join { error in
                if error == .channelErrorOk {
                    observer(.completed)
                } else {
                    observer(.error("join channel error \(error)"))
                }
            }
            return Disposables.create()
        }
    }
    
    func login() -> Completable {
        return .create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            self.agoraKit.login(byToken: self.rtmToken,
                                user: self.rtmUserUUID) { code in
                if code == .ok {
                    observer(.completed)
                } else {
                    observer(.error("login error \(code)"))
                }
            }
            return Disposables.create()
        }
    }
}

extension ClassRoomRtm2: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        print("rtm state update \(state.rawValue), reson \(reason.rawValue)")
        switch state {
        case .aborted:
            error.onError("another instance has login")
        default:
            return
        }
    }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        // ChannelStatus command is come from p2p
        do {
            print("receive p2p msg \(message.text), from \(peerId)")
            // TODO: Should check "r" is equal to 'self.commandChannelId'
            let command = try commandDecoder.decode(message.text)
            self.commandPublish.onNext((peerId, command))
        }
        catch {
            print("decoder p2p command error, \(error)")
        }
    }
}

extension ClassRoomRtm2: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        if  member.channelId == commandChannelId {

        } else {
            newMemberPublish.onNext(member.userId)
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        if member.channelId == commandChannelId {

        } else {
            memberLeftPublish.onNext(member.userId)
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        if  member.channelId == commandChannelId {
            do {
                print("receive channel command \(message.text), from \(member.userId)")
                let command = try commandDecoder.decode(message.text)
                commandPublish.onNext((member.userId, command))
            }
            catch {
                print("commands error \(error), raw: \(message.text)")
            }
        } else {
            print("receive message \(message.text), id \(member.userId)")
            newMessagePublish.onNext(.user(.init(userId: member.userId, text: message.text)))
        }
    }
}
