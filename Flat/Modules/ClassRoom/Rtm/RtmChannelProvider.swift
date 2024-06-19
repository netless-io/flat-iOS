//
//  RtmChannelProvider.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol RtmChannelProvider {
    init(channelId: String, userId: String)
    var newMemberPublisher: PublishRelay<String> { get }
    var memberLeftPublisher: PublishRelay<String> { get }
    var newMessagePublish: PublishRelay<(text: String, date: Date, sender: String)> { get }
    var rawDataPublish: PublishRelay<(data: Data, sender: String)> { get }

    func sendRawData(_ data: Data) -> Single<Void>
    func sendMessage(_ text: String) -> Single<Void>
    func getMembers() -> Single<[String]>
}
