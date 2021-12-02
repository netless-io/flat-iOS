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
    var cachedUserName: [String: String]
    let rtm: AnyChannelHandler
    let notice: Observable<String>
    let isBanning: Driver<Bool>
    let isBanned: Driver<Bool>
    
    init(roomUUID: String,
         cachedUserName: [String : String],
         rtm: AnyChannelHandler,
         notice: Observable<String>,
         banning: Driver<Bool>,
         banned: Driver<Bool>) {
        self.rtm = rtm
        self.notice = notice
        self.roomUUID = roomUUID
        self.cachedUserName = cachedUserName
        self.isBanned = banned
        self.isBanning = banning
    }
    
    func tranform(input: Input) -> Output {
        let send = input.sendTap.withLatestFrom(input.textInput)
            .filter { $0.isNotEmptyOrAllSpacing }
            .flatMapLatest { [unowned self] text in
                self.rtm.sendMessage(text, appendToNewMessage: true)
                    .asDriver(onErrorJustReturn: ())
            }
        
        let sendMessageEnable = input.textInput.map {
            $0.isNotEmptyOrAllSpacing
        }.withLatestFrom(isBanned) { inputEnable, baned in
            return inputEnable && !baned
        }
        
        let history = requestHistory(channelId: rtm.channelId).asObservable().share(replay: 1, scope: .whileConnected)
        let newMessage = rtm.newMessagePublish.map { [Message.user(UserMessage.init(userId: $0.sender, text: $0.text))] }
        let noticeMessage = notice.map { [Message.notice($0)]}
        
        let rawMessages = Observable.of(history, newMessage, noticeMessage).merge()
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
        }
        
        return .init(message: result, sendMessage: send, sendMessageEnable: sendMessageEnable)
    }
    
    func userName(userIds: [String]) -> Observable<[String: String]> {
        guard !userIds.isEmpty else {
            return .just([:])
        }
        let ids = userIds.removeDuplicate()
        let cachedName = ids.compactMap { id -> (String, String)? in
            if let name = self.cachedUserName[id] {
                return (id, name)
            }
            return nil
        }
        let cachedDic = Dictionary(uniqueKeysWithValues: cachedName)
        let unCachedIds = ids.filter {
            !cachedUserName.keys.contains($0)
        }
        if unCachedIds.isEmpty {
            return .just(cachedDic)
        } else {
            return queryUserName(userIds: unCachedIds)
                .map { values -> [String: String] in
                    return values.merging(cachedName, uniquingKeysWith: { i, j in return i })
                }
        }
    }
    
    func queryUserName(userIds: [String]) -> Observable<[String: String]> {
        ApiProvider.shared.request(fromApi: MemberRequest(roomUUID: roomUUID, usersUUID: userIds))
            .map { result -> [String: String] in
                return result.response.mapValues {
                    $0.name
                }
            }
            .do(onNext: { [weak self] users in
                self?.cachedUserName.merge(users, uniquingKeysWith: { i, j in
                    return i
                })
            }).asObservable()
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
                            let historyMessages: [Message] = historyResult.result
                                .map { UserMessage(userId: $0.sourceUserId, text: $0.message) }
                                .map { Message.user($0) }
                                .reversed()
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
}
