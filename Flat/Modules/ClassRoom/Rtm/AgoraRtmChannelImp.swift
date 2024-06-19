//
//  AgoraRtmChannelImp.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AgoraRtmKit
import Foundation
import RxCocoa
import RxSwift

var sharedAgoraKit: AgoraRtmClientKit!
class AgoraRtmChannelImp: NSObject, RtmChannelProvider {
    var newMemberPublisher: RxRelay.PublishRelay<String> = .init()
    var memberLeftPublisher: RxRelay.PublishRelay<String> = .init()
    var newMessagePublish: RxRelay.PublishRelay<(text: String, date: Date, sender: String)> = .init()
    var rawDataPublish: RxRelay.PublishRelay<(data: Data, sender: String)> = .init()

    let channelId: String
    let userId: String
    required init(channelId: String, userId: String) {
        self.channelId = channelId
        self.userId = userId
        super.init()
        sharedAgoraKit.addDelegate(self)
    }

    deinit {
        sharedAgoraKit.removeDelegate(self)
        globalLogger.trace("\(self), channelId \(channelId) deinit")
    }

    func sendRawData(_ data: Data) -> RxSwift.Single<Void> {
        .create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            sharedAgoraKit.publish(channelName: channelId, data: data, option: nil) { response, error in
                if let error, error.errorCode != .ok {
                    observer(.failure("send message error \(error.errorCode.rawValue)"))
                    return
                }
                guard let response else { return }
                observer(.success(()))
            }
            return Disposables.create()
        }
    }

    func sendMessage(_ text: String) -> RxSwift.Single<Void> {
        let send = Single<Void>.create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            sharedAgoraKit.publish(channelName: channelId, message: text, option: nil) { response, error in
                if let error, error.errorCode != .ok {
                    observer(.failure("send message error \(error.errorCode.rawValue)"))
                    return
                }
                guard let response else { return }
                observer(.success(()))
            }
            return Disposables.create()
        }.do(onSuccess: { [weak self] in
            guard let self else { return }
            self.newMessagePublish.accept((text, Date(), self.userId))
        })
        return ApiProvider.shared.request(fromApi: MessageCensorRequest(text: text))
            .asSingle()
            .flatMap { r in r.valid ? send : .just(()) }
    }

    func getMembers() -> RxSwift.Single<[String]> {
        .create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            globalLogger.info("start get members")
            // TODO: 这里要分页，先不搞了。 这里人多的时候一定会出错。
            sharedAgoraKit.getPresence()?.whoNow(channelName: channelId, channelType: .message, options: nil, completion: { response, error in
                if let error, error.errorCode != .ok {
                    let strError = "get member error, \(error.errorCode)"
                    observer(.failure(strError))
                    globalLogger.error("\(strError)")
                    return
                }
                guard let response else { return }
                let memberIds = response.userStateList.map(\.userId)
                globalLogger.info("success get members \(memberIds)")
                observer(.success(memberIds))
            })
            return Disposables.create()
        }
    }
}

extension AgoraRtmChannelImp: AgoraRtmClientDelegate {
    func rtmKit(_: AgoraRtmClientKit, didReceivePresenceEvent event: AgoraRtmPresenceEvent) {
        guard event.channelName == channelId, let userId = event.publisher else { return }
        if event.type == .remoteJoinChannel {
            globalLogger.info("memberJoined \(userId)")
            newMemberPublisher.accept(userId)
        }
        if event.type == .remoteLeaveChannel {
            globalLogger.info("memberLeft \(userId)")
            memberLeftPublisher.accept(userId)
        }
    }

    func rtmKit(_: AgoraRtmClientKit, didReceiveMessageEvent event: AgoraRtmMessageEvent) {
        guard event.channelName == channelId else { return }
        let userId = event.publisher
        let text = event.message.stringData
        if userId == "flat-server" {
            do {
                // Forge a raw data msg. Because server can not send raw data msg!
                if let textData = text?.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970
                    let info = try decoder.decode(RoomExpireInfo.self, from: textData)
                    let msgData = try CommandEncoder().encode(.roomExpire(roomUUID: channelId, expireInfo: info))
                    rawDataPublish.accept((msgData, userId))
                }
            } catch {
                globalLogger.error("transform flat-server msg error, \(error)")
            }
            return
        }

        if let data = event.message.rawData {
            rawDataPublish.accept((data, userId))
        } else if let text {
            newMessagePublish.accept((text, Date(timeIntervalSince1970: TimeInterval(event.timestamp)), userId))
        }
    }
}
