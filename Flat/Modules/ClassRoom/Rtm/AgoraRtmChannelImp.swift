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

class AgoraRtmChannelImp: NSObject, AgoraRtmChannelDelegate, RtmChannelProvider {
    let newMemberPublisher: PublishRelay<String> = .init()
    let memberLeftPublisher: PublishRelay<String> = .init()
    let newMessagePublish: PublishRelay<(text: String, date: Date, sender: String)> = .init()
    let rawDataPublish: PublishRelay<(data: Data, sender: String)> = .init()

    var userUUID: String!
    var channelId: String!
    weak var channel: AgoraRtmChannel!

    deinit {
        globalLogger.trace("\(self), channelId \(channelId ?? "") deinit")
    }

    func sendRawData(_ data: Data) -> Single<Void> {
        .create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            let msg = AgoraRtmRawMessage(rawData: data, description: "")
            self.channel.send(msg) { error in
                if error == .errorOk {
                    observer(.success(()))
                } else {
                    observer(.failure("send message error \(error)"))
                }
            }
            return Disposables.create()
        }
    }

    func sendMessage(_ text: String) -> Single<Void> {
        let send = Single<Void>.create { [weak self] observer in
            guard let self else {
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
            guard let self else { return }
            self.newMessagePublish.accept((text, Date(), self.userUUID))
        })
        return ApiProvider.shared.request(fromApi: MessageCensorRequest(text: text))
            .asSingle()
            .flatMap { r in r.valid ? send : .just(()) }
    }

    func getMembers() -> Single<[String]> {
        .create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }
            globalLogger.info("start get members")
            self.channel.getMembersWithCompletion { members, error in
                guard error == .ok else {
                    let strError = "get member error, \(error.rawValue)"
                    observer(.failure(strError))
                    globalLogger.error("\(strError)")
                    return
                }
                let memberIds = members?.map(\.userId) ?? []
                globalLogger.info("success get members \(memberIds)")
                observer(.success(memberIds))
            }
            return Disposables.create()
        }
    }

    func channel(_: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        globalLogger.info("memberJoined \(member.userId)")
        newMemberPublisher.accept(member.userId)
    }

    func channel(_: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        globalLogger.info("memberLeft \(member.userId)")
        memberLeftPublisher.accept(member.userId)
    }

    func channel(_: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
//        globalLogger.info("receive \(type)
        switch message.type {
        case .text:
            if member.userId == "flat-server" {
                do {
                    // Forge a raw data msg. Because server can not send raw data msg!
                    if let textData = message.text.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .millisecondsSince1970
                        let info = try decoder.decode(RoomExpireInfo.self, from: textData)
                        let msgData = try CommandEncoder().encode(.roomExpire(roomUUID: channelId, expireInfo: info))
                        rawDataPublish.accept((msgData, member.userId))
                    }
                } catch {
                    globalLogger.error("transform flat-server msg error, \(error)")
                }
                return
            }
            newMessagePublish.accept((message.text, Date(timeIntervalSince1970: TimeInterval(message.serverReceivedTs)), member.userId))
        case .raw:
            if let rawMessage = message as? AgoraRtmRawMessage {
                rawDataPublish.accept((rawMessage.rawData, member.userId))
            }
        default:
            return
        }
    }
}

extension AgoraRtmMessageType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .undefined:
            return "undefined"
        case .text:
            return "text"
        case .raw:
            return "raw"
        case .file:
            return "file"
        case .image:
            return "image"
        @unknown default:
            return "undefined"
        }
    }
}
