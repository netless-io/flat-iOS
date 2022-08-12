//
//  ChatViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/16.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxCocoa
import RxSwift

enum DisplayMessage {
    case user(message: UserMessage, name: String)
    case notice(String)
}

typealias UsernameQueryProvider = (([String]) -> Observable<[String: String]>)

class ChatViewModel {
    struct Input {
        let sendTap: Driver<Void>
        let textInput: Driver<String>
    }
    struct Output {
        let message: Observable<[DisplayMessage]>
        let sendMessage: Driver<Void>
        let sendMessageEnable: Driver<Bool>
    }
    
    let roomUUID: String
    let userNameProvider: UsernameQueryProvider
    let rtm: RtmChannel
    let notice: Observable<String>
    let isOwner: Bool
    let isBanned: Driver<Bool>
    let banMessagePublisher: PublishRelay<Bool>
    
    init(roomUUID: String,
         userNameProvider: @escaping UsernameQueryProvider,
         rtm: RtmChannel,
         notice: Observable<String>,
         isBanned: Driver<Bool>,
         isOwner: Bool,
         banMessagePublisher: PublishRelay<Bool>) {
        self.rtm = rtm
        self.notice = notice
        self.userNameProvider = userNameProvider
        self.roomUUID = roomUUID
        self.isBanned = isBanned
        self.isOwner = isOwner
        self.banMessagePublisher = banMessagePublisher
    }
    
    func transform(input: Input) -> Output {
        let send = input.sendTap.withLatestFrom(input.textInput)
            .filter { $0.isNotEmptyOrAllSpacing }
            .flatMapLatest { [unowned self] text in
                self.rtm.sendMessage(text, censor: true, appendToNewMessage: true)
                    .asDriver(onErrorJustReturn: ())
            }
        
        let sendMessageEnable: Driver<Bool>
        
        if isOwner {
            sendMessageEnable = input.textInput.map { $0.isNotEmptyOrAllSpacing }
        } else {
            sendMessageEnable = input.textInput
                .map { $0.isNotEmptyOrAllSpacing }
                .withLatestFrom(isBanned) { inputEnable, banned in
                    return inputEnable && !banned
                }
        }
        
        let history = requestHistory(channelId: rtm.channelId).asObservable().share(replay: 1, scope: .whileConnected)
        let newMessage = rtm.newMessagePublish.map { [Message.user(UserMessage.init(userId: $0.sender, text: $0.text))] }
        let noticeMessage = notice.map { [Message.notice($0)]}
        let banMessage   = banMessagePublisher.map { [Message.notice(NSLocalizedString($0 ? "All banned" : "The ban was lifted", comment: ""))]}
        
        let rawMessages = Observable.of(history, newMessage, noticeMessage,banMessage)
            .merge()
            .scan([Message](), accumulator: {
                var r = $0
                r.append(contentsOf: $1)
                return r
            })
        
        let nameResult = rawMessages.flatMap { message -> Observable<[String: String]> in
            let ids = message.compactMap { $0.userId }
            return self.userName(userIds: ids)
        }
        
        let result = nameResult.withLatestFrom(rawMessages) { dic, msgs in
            return msgs.map { msg -> DisplayMessage in
                switch msg {
                case .notice(let text): return .notice(text)
                case .user(let user): return .user(message: user, name: dic[user.userId]!)
                }
            }
        }.debug("msg:: ", trimOutput: false)
        
        return .init(message: result, sendMessage: send, sendMessageEnable: sendMessageEnable)
    }
    
    func userName(userIds: [String]) -> Observable<[String: String]> {
        guard !userIds.isEmpty else { return .just([:]) }
        let ids = userIds.removeDuplicate()
        return userNameProvider(ids)
    }
    
    func requestHistory(channelId: String) -> Single<[Message]> {
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
                    log(module: .rtm, level: .error, log: "request history source error \(error)")
                    observer(.failure(error))
                case .success(let value):
                    var path = value.result
                    if path.hasPrefix("~") {
                        path.removeFirst()
                    }
                    ApiProvider.shared.request(fromApi: HistoryMessageRequest(messagePath: path)) { result in
                        switch result {
                        case .success(let historyResult):
                            let historyMessages: [Message] = historyResult.result
                                .map { UserMessage(userId: $0.sourceUserId, text: $0.message) }
                                .map { Message.user($0) }
                                .reversed()
                            observer(.success(historyMessages))
                        case .failure(let error):
                            log(module: .rtm, level: .error, log: "request history source error \(error)")
                            observer(.failure(error))
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
}
