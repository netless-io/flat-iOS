//
//  RtmProvider.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

enum RtmError {
    case remoteLogin
    case reconnectingTimeout
}

enum RtmState {
    case idle
    case connecting
    case reconnecting
    case connected
}

protocol RtmProvider {
    var error: PublishRelay<RtmError> { get }
    var p2pMessage: PublishRelay<(data: Data, sender: String)> { get }
    
    func sendP2PMessageFromArray(_ array: [(data: Data, uuid: String)]) -> Single<Void>
    func sendP2PMessage(data: Data, toUUID UUID: String) -> Single<Void>
    func login() -> Single<Void>
    func logout() -> Single<Void>
}
