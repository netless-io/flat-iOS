//
//  AgoraRtm.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AgoraRtmKit
import Foundation
import RxRelay
import RxSwift

/// Rtm state control
class AgoraRtm: NSObject, RtmProvider {
    let p2pMessage: PublishRelay<(data: Data, sender: String)> = .init()
    let error: PublishRelay<RtmError> = .init()
    let state: BehaviorRelay<RtmState> = .init(value: .idle)
    let reconnectTimeoutInterval: DispatchTimeInterval = .seconds(5)
    let rtmToken: String
    let rtmUserId: String

    init(rtmToken: String,
         rtmUserUUID: String,
         agoraAppId: String)
    {
        self.rtmToken = rtmToken
        rtmUserId = rtmUserUUID
        super.init()
        do {
            let config = AgoraRtmClientConfig(appId: agoraAppId, userId: rtmUserUUID)
            agoraKit = try AgoraRtmClientKit(config, delegate: self)
        } catch {
            globalLogger.error("init agorakit error \(error)")
        }
        agoraGenerator.agoraToken = rtmToken
        agoraGenerator.agoraUserId = rtmUserUUID
        globalLogger.trace("\(self)")
    }

    deinit {
        agoraKit.removeDelegate(self)
        globalLogger.trace("\(self) deinit")
    }

    func sendP2PMessageFromArray(_ array: [(data: Data, uuid: String)]) -> Single<Void> {
        array.reduce(Single<Void>.just(())) { [weak self] partial, part -> Single<Void> in
            guard let self else { return .error("self not exist") }
            return partial.flatMap { _ -> Single<Void> in
                self.sendP2PMessage(data: part.data, toUUID: part.uuid)
            }
        }
    }

    func sendP2PMessage(data: Data, toUUID UUID: String) -> Single<Void> {
        globalLogger.info("send p2p raw message data, to \(UUID)")
        switch state.value {
        case .connecting, .idle, .reconnecting: return .just(())
        case .connected:
            return .create { [weak self] observer in
                guard let self else {
                    observer(.failure("self not exist"))
                    return Disposables.create()
                }
                let options = AgoraRtmPublishOptions()
                options.channelType = .user
                self.agoraKit.publish(channelName: UUID, data: data, option: options) { _, error in
                    if let error, error.errorCode != .ok {
                        let errMsg = "send p2p msg error \(error.errorCode.rawValue)"
                        globalLogger.error("\(errMsg)")
                        if error.errorCode == .presenceUserNotExist { // TOOD: 还不知道是不是这个错误。
                            observer(.failure(localizeStrings("UserNotInRoom")))
                        } else {
                            observer(.failure(errMsg))
                        }
                        return
                    }
                    observer(.success(()))
                }
                return Disposables.create()
            }
        }
    }

    var loginCallbacks: [(AgoraRtmErrorCode) -> Void] = []
    /// Can be called safely multi times
    func login() -> Single<Void> {
        func createLoginObserver() -> Single<Void> {
            .create { [weak self] observer in
                guard let self else {
                    observer(.failure("self not exist"))
                    return Disposables.create()
                }
                self.loginCallbacks.append { code in
                    if code == AgoraRtmErrorCode.ok {
                        observer(.success(()))
                    } else {
                        observer(.failure("login error \(code)"))
                    }
                }
                return Disposables.create()
            }
        }
        switch state.value {
        case .connected, .reconnecting: return .just(())
        case .connecting: return createLoginObserver()
        case .idle:
            globalLogger.info("start login: \(rtmToken), \(rtmUserId)")
            agoraKit.login(rtmToken) { [weak self] response, errorInfo in
                guard let self else { return }
                if let errorInfo, errorInfo.errorCode != .ok {
                    let code = errorInfo.errorCode
                    globalLogger.error("login failed. code \(code)")
                    self.loginCallbacks.forEach { $0(code) }
                    self.loginCallbacks = []
                    self.state.accept(.idle)
                    return
                }
                guard let response else { return } // TODO: 这个 response 来干啥的？？
                globalLogger.info("login success")
                self.loginCallbacks.forEach { $0(.ok) }
                self.loginCallbacks = []
                self.state.accept(.connected)
            }
            return createLoginObserver()
        }
    }

    func logout() -> Single<Void> {
        switch state.value {
        case .idle, .connecting, .reconnecting: return .just(())
        case .connected:
            return Single<Void>.create { [weak self] observer in
                self?.agoraKit.logout { _, error in
                    self?.agoraKit.destroy()
                    if let error, error.errorCode != .ok {
                        observer(.failure("rtm logout \(error.errorCode.rawValue)"))
                        return
                    }
                    observer(.success(()))
                }
                return Disposables.create()
            }
        }
    }

    func joinChannelId(_ channelId: String) -> Single<RtmChannelProvider> {
        .create { [weak self] observer in
            guard let self else {
                observer(.failure("self not exist"))
                return Disposables.create()
            }

            let rtmUserId = self.rtmUserId
            globalLogger.info("start join channel: \(channelId)")
            let options = AgoraRtmSubscribeOptions()
            options.features = [.message, .presence]
            sharedAgoraKit = agoraKit
            agoraKit.subscribe(channelName: channelId, option: options) { response, error in
                if let error, error.errorCode != .ok {
                    globalLogger.error("join channel: \(channelId) fail, \(error.errorCode.rawValue)")
                    observer(.failure("join channel error \(error)"))
                    return
                }
                guard let response else { return }
                globalLogger.info("start join channel: \(channelId) success")
                let handler = AgoraRtmChannelImp(channelId: channelId, userId: rtmUserId)
                observer(.success(handler))
            }
            return Disposables.create()
        }
    }

    fileprivate var agoraKit: AgoraRtmClientKit!
}

extension AgoraRtm: AgoraRtmClientDelegate {
    func rtmKit(_: AgoraRtmClientKit, channel _: String, connectionChangedToState state: AgoraRtmClientConnectionState, reason: AgoraRtmClientConnectionChangeReason) {
        globalLogger.info("state \(state), reason \(reason)")
        switch state {
        case .connected:
            self.state.accept(.connected)
        case .connecting:
            self.state.accept(.connecting)
        case .reconnecting:
            self.state.accept(.reconnecting)
            DispatchQueue.global().asyncAfter(deadline: .now() + reconnectTimeoutInterval) { [weak self] in
                guard let self else { return }
                if self.state.value == .reconnecting {
                    DispatchQueue.main.async {
                        self.error.accept(.reconnectingTimeout)
                    }
                }
            }
        case .disconnected:
            if reason == .changedSameUidLogin {
                globalLogger.error("remote login")
                error.accept(.remoteLogin)
            }
        default:
            return
        }
    }

    func rtmKit(_: AgoraRtmClientKit, didReceiveMessageEvent event: AgoraRtmMessageEvent) {
        guard event.channelType == .user else { return }
        if let data = event.message.rawData {
            globalLogger.info("receive p2p message \(data.count) b")
            p2pMessage.accept((data, event.publisher))
        }
    }
}

extension AgoraRtmClientConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected:
            "disconnected"
        case .connecting:
            "connecting"
        case .connected:
            "connected"
        case .reconnecting:
            "reconnecting"
        case .failed:
            "failed"
        @unknown default:
            "default \(rawValue)"
        }
    }
}

extension AgoraRtmClientConnectionChangeReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .changedConnecting:
            "changedConnecting"
        case .changedJoinSuccess:
            "changedJoinSuccess"
        case .changedInterrupted:
            "changedInterrupted"
        case .changedBannedByServer:
            "changedBannedByServer"
        case .changedJoinFailed:
            "changedJoinFailed"
        case .changedLeaveChannel:
            "changedLeaveChannel"
        case .changedInvalidAppId:
            "changedInvalidAppId"
        case .changedInvalidChannelName:
            "changedInvalidChannelName"
        case .changedInvalidToken:
            "changedInvalidToken"
        case .changedTokenExpired:
            "changedTokenExpired"
        case .changedRejectedByServer:
            "changedRejectedByServer"
        case .changedSettingProxyServer:
            "changedSettingProxyServer"
        case .changedRenewToken:
            "changedRenewToken"
        case .changedClientIpAddressChanged:
            "changedClientIpAddressChanged"
        case .changedKeepAliveTimeout:
            "changedKeepAliveTimeout"
        case .changedRejoinSuccess:
            "changedRejoinSuccess"
        case .changedChangedLost:
            "changedChangedLost"
        case .changedEchoTest:
            "changedEchoTest"
        case .changedClientIpAddressChangedByUser:
            "changedClientIpAddressChangedByUser"
        case .changedSameUidLogin:
            "changedSameUidLogin"
        case .changedTooManyBroadcasters:
            "changedTooManyBroadcasters"
        case .changedLicenseValidationFailure:
            "changedLicenseValidationFailure"
        case .changedCertificationVerifyFailure:
            "changedCertificationVerifyFailure"
        case .changedStreamChannelNotAvailable:
            "changedStreamChannelNotAvailable"
        case .changedInconsistentAppId:
            "changedInconsistentAppId"
        case .changedLoginSuccess:
            "changedLoginSuccess"
        case .changedLogout:
            "changedLogout"
        case .changedPresenceNotReady:
            "changedPresenceNotReady"
        @unknown default:
            "default \(rawValue)"
        }
    }
}
