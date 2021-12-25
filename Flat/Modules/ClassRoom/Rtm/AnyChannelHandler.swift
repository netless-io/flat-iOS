//
//  ClassRoomCommand.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import AgoraRtmKit
import RxSwift
import RxCocoa

class AnyChannelHandler: NSObject, AgoraRtmChannelDelegate {
    let newMemberPublisher: PublishRelay<String> = .init()
    let memberLeftPublisher: PublishRelay<String> = .init()
    let newMessagePublish: PublishRelay<(text: String, sender: String)> = .init()
    
    var userUUID: String!
    var channelId: String!
    weak var channel: AgoraRtmChannel!
    
    deinit {
        print(self, channelId ?? "", "deinit")
    }
    
    func sendMessage(_ text: String, appendToNewMessage: Bool = false) -> Single<Void> {
        .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            self.channel.send(.init(text: text)) { error in
                if error == .errorOk {
                    observer(.success(()))
                } else {
                    observer(.failure("send message error \(error)"))
                }
            }
            return Disposables.create()
        }.do(onSuccess: { [weak self] in
            guard let self = self else { return }
            if appendToNewMessage {
                self.newMessagePublish.accept((text, self.userUUID))
            }
        })
    }
    
    func getMembers() -> Single<[String]> {
        return .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            self.channel.getMembersWithCompletion { members, error in
                guard error == .ok else {
                    observer(.failure("fetch member error, \(error.rawValue)"))
                    return
                }
                let memberIds = members?.map { $0.userId } ?? []
                observer(.success(memberIds))
            }
            return Disposables.create()
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        print(#function, member.userId)
        newMemberPublisher.accept(member.userId)
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        print(#function, member.userId)
        memberLeftPublisher.accept(member.userId)
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        print(#function, message.text)
        newMessagePublish.accept((message.text, member.userId))
    }
}
