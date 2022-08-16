//
//  Rtc.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import AgoraRtcKit
import RxSwift
import RxRelay

enum RtcError {
    case connectionLost
}

class Rtc: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    let screenShareInfo: ShareScreenInfo?
    let screenShareJoinBehavior: BehaviorRelay<Bool> = .init(value: false)
    let errorPublisher = PublishRelay<RtcError>.init()
    private var joinChannelBlock: (()->Void)?
    let isJoined = BehaviorRelay<Bool>.init(value: false)
    var targetLocalMic: Bool? = false
    var targetLocalCamera: Bool? = false
    
    // MARK: - Public
    func joinChannel() { joinChannelBlock?() }
    
    func leave() -> Single<Void> {
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        AgoraRtcEngineKit.destroy()
        isJoined.accept(false)
        return .just(())
    }
    
    func updateRemoteUserStreamType(rtcUID: UInt, type: AgoraVideoStreamType) {
        agoraKit.setRemoteVideoStream(rtcUID, type: type)
    }
    
    func updateRemoteUser(rtcUID: UInt, cameraOn: Bool, micOn: Bool) {
        agoraKit.muteRemoteVideoStream(rtcUID, mute: !cameraOn)
        agoraKit.muteRemoteAudioStream(rtcUID, mute: !micOn)
    }
    
    func updateLocalUser(cameraOn: Bool) {
        if isJoined.value {
            targetLocalCamera = nil
            agoraKit.enableLocalVideo(cameraOn)
            agoraKit.muteLocalVideoStream(!cameraOn)
            logger.info("update local user status camera: \(cameraOn)")
        } else {
            targetLocalCamera = cameraOn
            logger.trace("update local user status camera: \(cameraOn) to target")
        }
    }
    
    func updateLocalUser(micOn: Bool) {
        if isJoined.value {
            targetLocalMic = nil
            agoraKit.enableLocalAudio(micOn)
            agoraKit.muteLocalAudioStream(!micOn)
            logger.info("update local user status mic: \(micOn)")
        } else {
            targetLocalMic = micOn
            logger.trace("update local user status mic: \(micOn) to target")
        }
    }
    
    func createOrFetchFromCacheCanvas(for uid: UInt) -> AgoraRtcVideoCanvas {
        if let canvas = remoteCanvas[uid] {
            return canvas
        } else {
            let canvas = AgoraRtcVideoCanvas()
            canvas.uid = uid
            canvas.mirrorMode = .enabled
            canvas.renderMode = .hidden
            remoteCanvas[uid] = canvas
            return canvas
        }
    }
    
    var remoteCanvas: [UInt: AgoraRtcVideoCanvas] = [:]
    lazy var screenShareCanvas: AgoraRtcVideoCanvas = {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = UInt(screenShareInfo?.uid ?? 0)
        canvas.renderMode = AgoraVideoRenderMode.fit
        return canvas
    }()
    var localVideoCanvas: AgoraRtcVideoCanvas!
    
    init(appId: String,
         channelId: String,
         token: String,
         uid: UInt,
         screenShareInfo: ShareScreenInfo?) {
        self.screenShareInfo = screenShareInfo
        super.init()
        agoraKit = .sharedEngine(withAppId: appId, delegate: self)
        
        agoraKit.setLogFile("") // set to default path
        agoraKit.setLogFilter(AgoraLogFilter.error.rawValue)
        
        // 大流720P视频
        let config = AgoraVideoEncoderConfiguration(size: .init(width: 1280, height: 720), frameRate: .fps15, bitrate: 1130, orientationMode: .adaptative)
        agoraKit.setVideoEncoderConfiguration(config)
        // 各发流端在加入频道前或者后，都可以调用 enableDualStreamMode 方法开启双流模式。
        agoraKit.enableDualStreamMode(true)
        // 启用针对多人通信场景的优化策略。
        agoraKit.setParameters("{\"che.audio.live_for_comm\": true}")
        // Agora 建议自定义的小流分辨率不超过 320 × 180 px，码率不超过 140 Kbps，且小流帧率不能超过大流帧率。
        agoraKit.setParameters("{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":5,\"bitRate\":140}}")
        agoraKit.enableVideo()
        
        joinChannelBlock = { [weak self] in
            let canvas = AgoraRtcVideoCanvas()
            canvas.uid = uid
            canvas.renderMode = .hidden
            self?.localVideoCanvas = canvas

            logger.info("start join channel: \(channelId) uid: \(uid)")
            self?.agoraKit.joinChannel(byToken: token,
                                       channelId: channelId,
                                       info: nil,
                                       uid: uid, joinSuccess: { [weak self] msg, uid, elapsed in
                logger.info("end join \(msg), elapsed \(elapsed)")
                self?.isJoined.accept(true)
            })
        }
        joinChannel()

        isJoined
            .filter { $0 }
            .subscribe(with: self, onNext: { weakSelf, _ in
                if let targetLocalMic = weakSelf.targetLocalMic {
                    weakSelf.updateLocalUser(micOn: targetLocalMic)
                }
                if let targetLocalCamera = weakSelf.targetLocalCamera {
                    weakSelf.updateLocalUser(cameraOn: targetLocalCamera)
                }
            })
            .disposed(by: rx.disposeBag)
    }
}

extension Rtc: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        logger.warning("didOccurWarning \(warningCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        logger.error("didOccurError \(errorCode)")
    }
    
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        logger.error("lost connection")
        errorPublisher.accept(.connectionLost)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        switch state {
        case .disconnected, .connecting, .reconnecting, .failed:
            isJoined.accept(false)
        case .connected:
            isJoined.accept(true)
        @unknown default: break
        }
        logger.info("connectionChangedTo \(state) \(reason)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute error: Int, api: String, result: String) {}
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {}
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {}
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if isScreenShareUid(uid: uid) {
            screenShareJoinBehavior.accept(false)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        if isScreenShareUid(uid: uid) {
            screenShareJoinBehavior.accept(true)
        }
    }
    
    func isScreenShareUid(uid: UInt) -> Bool {
        if let id = screenShareInfo?.uid, id == uid { return true }
        return false
    }
}

extension AgoraConnectionStateType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .reconnecting:
            return "reconnecting"
        case .failed:
            return "failed"
        @unknown default: return "unknown \(rawValue)"
        }
    }
}

extension AgoraConnectionChangedReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting: return "connecting"
        case .joinSuccess: return "joinSuccess"
        case .interrupted: return "interrupted"
        case .bannedByServer: return "bannedByServer"
        case .joinFailed: return "joinFailed"
        case .leaveChannel: return "leaveChannel"
        case .invalidAppId: return "invalidAppId"
        case .invalidChannelName: return "invalidChannelName"
        case .invalidToken: return "invalidToken"
        case .tokenExpired: return "tokenExpired"
        case .rejectedByServer: return "rejectedByServer"
        case .settingProxyServer: return "settingProxyServer"
        case .renewToken: return "renewToken"
        case .clientIpAddressChanged: return "clientIpAddressChanged"
        case .keepAliveTimeout: return "keepAliveTimeout"
        case .sameUidLogin: return "sameUidLogin"
        case .tooManyBroadcasters: return "tooManyBroadcasters"
        @unknown default: return "unknown \(rawValue)"
        }
    }
}
