//
//  ClassRoomRTM.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import AgoraRtmKit

class ClassRoomRtm: NSObject {
    weak var delegate: ClassRoomRtmDelegate?
    var agoraKit: AgoraRtmKit!
    var channel: AgoraRtmChannel?
    var commandChannel: AgoraRtmChannel?
    let rtmToken: String
    let roomUID: String
    let roomUUID: String
    var commandChannelId: String { roomUUID + "commands" }
    
    var commandDecoder = CommandDecoder()
    var commandEncoder = CommandEncoder()

    deinit {
        print(self, "destory")
    }
    
    init(rtmToken: String, roomUID: String, roomUUID: String) {
        self.roomUUID = roomUUID
        self.rtmToken = rtmToken
        self.roomUID = roomUID
        super.init()
        agoraKit = AgoraRtmKit.init(appId: Env().agoraAppId, delegate: self)
    }
    
    // MARK: - Public
    func leave() {
        agoraKit.logout { errCode in
            print(errCode)
        }
    }
    
    func sendCommand(_ command: RtmCommand, toTargetUID targetId: String?) throws {
        if let targetId = targetId {
            let str = try commandEncoder.encode(command, withChannelId: commandChannelId)
            print("send command \(str), to \(targetId)")
            agoraKit.send(.init(text: str), toPeer: targetId) { error in
                print("send p2p \(error == .ok), \(error.rawValue)")
            }
        } else {
            let str = try commandEncoder.encode(command, withChannelId: nil)
            commandChannel?.send(.init(text: str), completion: nil)
            print("send command \(str), to channel")
        }
    }
    
    func joinChannel(completion: @escaping ((Error?) ->Void)) {
        agoraKit.login(byToken: rtmToken, user: roomUID) { errCode in
            guard errCode == .ok else {
                completion("rtm login fail, code \(errCode.rawValue)")
                return
            }
            // Enter message channel
            self.channel = self.agoraKit.createChannel(withId: self.roomUUID, delegate: self)
            self.channel?.join(completion: { joinErrCode in
                guard joinErrCode == .channelErrorOk else {
                    completion("rtm join channel fail, code \(joinErrCode.rawValue)")
                    return
                }
                // Enter command channel
                self.commandChannel = self.agoraKit.createChannel(withId: self.commandChannelId, delegate: self)
                self.commandChannel?.join(completion: { joinCommandErrorCode in
                    guard joinCommandErrorCode == .channelErrorOk else {
                        completion("rtm join command channel fail, code \(joinCommandErrorCode.rawValue)")
                        return
                    }
                    completion(nil)
                })
            })
        }
    }
    
    func requestHistory(channelId: String, completion: @escaping ((Result<[Message], Error>)->Void)) {
        let endTime = Date()
        let startTime = Date(timeInterval: -(3600 * 24), since: endTime)
        let request = HistoryMessageSourceRequest(filter: .init(destination: channelId,
                                                                startTime: startTime,
                                                                endTime: endTime),
                                                  offSet: 0)
        ApiProvider.shared.request(fromApi: request) { result in
            switch result {
            case .failure(let error):
                print(error)
                completion(.failure(error))
            case .success(let value):
                var path = value.result
                if path.hasPrefix("~") {
                    path.removeFirst()
                }
                ApiProvider.shared.request(fromApi: HistoryMessageRequest(path: path)) { result in
                    switch result {
                    case .success(let historyResult):
                        let historyMessages = historyResult.result.map { UserMessage(userId: $0.sourceUserId, text: $0.message) }.map { Message.user($0) }
                        completion(.success(historyMessages))
                    case .failure(let error):
                        print(error)
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func sendMessage(_ text: String) {
        let msg = AgoraRtmMessage(text: text)
        channel?.send(msg) { errCode in
            print(#function, errCode.rawValue)
        }
    }
    
    // MARK: - Private

}

extension ClassRoomRtm: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        switch state {
        case .aborted:
            delegate?.classRoomRtm(self, error: "another instance has login")
        default:
            return
        }
        print("rtm state update \(state.rawValue), reson \(reason.rawValue)")
    }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        // ChannelStatus command is come from p2p
        do {
            // TODO: Should check "r" is equal to 'self.commandChannelId'
            let command = try commandDecoder.decode(message.text)
            delegate?.classRoomRtmDidReceiveCommand(self, command: command, senderId: peerId)
        }
        catch {
            print("parse p2p command error, \(error)")
        }
    }
}

extension ClassRoomRtm: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        print(#function)
        if  member.channelId == commandChannelId {
            
        } else {
            delegate?.classRoomRtmMemberJoined(self, memberUserId: member.userId)
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        if member.channelId == commandChannelId {
            
        } else {
            delegate?.classRoomRtmMemberLeft(self, memberUserId: member.userId)
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        print(#function, message)
        
        if  member.channelId == commandChannelId {
            do {
                let command = try commandDecoder.decode(message.text)
                delegate?.classRoomRtmDidReceiveCommand(self, command: command, senderId: member.userId)
            }
            catch {
                print("commands error \(error), raw: \(message.text)")
            }
        } else {
            delegate?.classRoomRtmDidReceiveMessage(self, message: .init(userId: member.userId, text: message.text))
        }
    }
}


