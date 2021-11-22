//
//  ClassRoomRtm.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import AgoraRtmKit
import RxSwift
import RxRelay

class ClassRoomRtm: NSObject {
    fileprivate var agoraKit: AgoraRtmKit!
    fileprivate let rtmToken: String
    fileprivate let rtmUserUUID: String
    
    let p2pMessage: PublishRelay<(text: String, userId: String)> = .init()
    
    init(rtmToken: String,
         rtmUserUUID: String,
         agoraAppId: String) {
        self.rtmToken = rtmToken
        self.rtmUserUUID = rtmUserUUID
        super.init()
        agoraKit = AgoraRtmKit(appId: agoraAppId, delegate: self)!
        agoraGenerator.agoraToken = rtmToken
        agoraGenerator.agoraUserId = rtmUserUUID
    }

    deinit {
        print("rtm deinit")
    }
    
    func sendMessage(text: String, toUUID UUID: String) -> Single<Void> {
        return .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            self.agoraKit.send(.init(text: text), toPeer: UUID) { error in
                if error == .ok {
                    observer(.success(()))
                } else {
                    observer(.failure("send p2p msg error \(error)"))
                }
            }
            return Disposables.create()
        }
    }
    
    func login() -> Single<Void> {
        return .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            self.agoraKit.login(byToken: self.rtmToken,
                                user: self.rtmUserUUID) { code in
                if code == .ok || code == .alreadyLogin {
                    observer(.success(()))
                } else {
                    observer(.failure("login error \(code)"))
                }
            }
            return Disposables.create()
        }
    }
    
    func leave() -> Single<Void> {
        return .create { [weak self] observer in
            self?.agoraKit.logout(completion: { error in
                if error == .ok {
                    observer(.success(()))
                } else {
                    observer(.failure("rtm logout \(error)"))
                }
            })
            return Disposables.create()
        }
    }
    
    func joinChannelId(_ channelId: String) -> Single<AnyChannelHandler> {
        .create { [weak self] observer in
            guard let self = self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            let handler = AnyChannelHandler()
            handler.userUUID = self.rtmUserUUID
            handler.channelId = channelId
            let channel = self.agoraKit.createChannel(withId: channelId, delegate: handler)!
            handler.channel = channel
            channel.join { error in
                if error == .channelErrorOk {
                    observer(.success(handler))
                } else {
                    observer(.failure("join channel error \(error)"))
                }
            }
            return Disposables.create()
        }
    }
}

extension ClassRoomRtm: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
//        print("rtm state update \(state.rawValue), reson \(reason.rawValue)")
//        switch state {
//        case .aborted:
//            error.onError("another instance has login")
//        default:
//            return
//        }
    }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        p2pMessage.accept((message.text, peerId))
    }
}
