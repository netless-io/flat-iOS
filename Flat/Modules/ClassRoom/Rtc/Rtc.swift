//
//  Rtc.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AgoraRtcKit
import Foundation
import RxRelay
import RxSwift
import UIKit

enum RtcError {
    case connectionLost
}

private func encodeConfigWith(mirror: Bool) -> AgoraVideoEncoderConfiguration {
    let isPhone = UIDevice().userInterfaceIdiom == .phone
    return AgoraVideoEncoderConfiguration(
        size: .init(width: 1280, height: 720),
        frameRate: .fps15,
        bitrate: 1130,
        orientationMode: isPhone ? .fixedLandscape : .adaptative,
        mirrorMode: mirror ? .enabled : .disabled
    )
}

class Rtc: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    let screenShareInfo: ShareScreenInfo?
    let screenShareJoinBehavior: BehaviorRelay<Bool> = .init(value: false)
    let errorPublisher = PublishRelay<RtcError>.init()
    let lastMileDelay = BehaviorRelay<Int>.init(value: 0)
    let networkStatusBehavior = BehaviorRelay<AgoraNetworkQuality>.init(value: .bad)
    private var joinChannelBlock: (() -> Void)?
    let isJoined = BehaviorRelay<Bool>.init(value: false)
    var targetLocalMic: Bool? = false
    var targetLocalCamera: Bool? = false
    var micStrenths: [UInt: PublishRelay<CGFloat>] = [:]
    var isFrontMirror: Bool
    var isUsingFront: Bool
    lazy var isBroadcaster: Bool = false
    var localCameraOn: Bool {
        didSet {
            if localCameraOn == oldValue { return }
            _performCameraStateUpdate()
        }
    }

    private func _performCameraStateUpdate() {
        agoraKit.enableLocalVideo(localCameraOn)
        agoraKit.muteLocalVideoStream(!localCameraOn)
        if localCameraOn {
            agoraKit.startPreview()
        } else {
            agoraKit.stopPreview()
        }
        logger.info("update local user status camera: \(localCameraOn)")
        updateClienRoleIfNeed()
    }

    var localAudioOn: Bool {
        didSet {
            if localAudioOn == oldValue { return }
            _performAudioStateUpdate()
        }
    }
    
    
    @objc fileprivate func _updateAINS() {
        let isAINS = PerferrenceManager.shared.preferences[.ains] ?? true
        logger.info("update ains \(isAINS)")
        // 4.2 的 AI 降噪
        agoraKit.setAINSMode(isAINS, mode: .AINS_MODE_BALANCED)
    }

    private func _performAudioStateUpdate() {
        agoraKit.enableLocalAudio(localAudioOn)
        agoraKit.muteLocalAudioStream(!localAudioOn)
        logger.info("update local user status mic: \(localAudioOn)")
        updateClienRoleIfNeed()
    }

    func updateClienRoleIfNeed() {
        if localCameraOn || localAudioOn {
            if !isBroadcaster {
                isBroadcaster = true
                let result = agoraKit.setClientRole(.broadcaster)
                logger.info("set client role broadcaster \(result)")
                return
            }
        }
        if !localAudioOn, !localCameraOn {
            if isBroadcaster {
                isBroadcaster = false
                let result = agoraKit.setClientRole(.audience)
                logger.info("set client role audience \(result)")
                return
            }
        }
    }

    @objc func onClassroomSettingNeedToggleFronMirrorNotification() {
        isFrontMirror.toggle()
        agoraKit.setLocalRenderMode(.hidden, mirror: isFrontMirror ? .enabled : .disabled)
        agoraKit.setVideoEncoderConfiguration(encodeConfigWith(mirror: isFrontMirror))
    }

    @objc func onClassroomSettingNeedToggleCameraNotification() {
        isUsingFront.toggle()
        agoraKit.switchCamera()
        if !isUsingFront {
            agoraKit.setLocalRenderMode(.hidden, mirror: .disabled)
            agoraKit.setVideoEncoderConfiguration(encodeConfigWith(mirror: false))
        } else {
            agoraKit.setLocalRenderMode(.hidden, mirror: isFrontMirror ? .enabled : .disabled)
            agoraKit.setVideoEncoderConfiguration(encodeConfigWith(mirror: isFrontMirror))
        }
    }

    // MARK: - Public

    func joinChannel() { joinChannelBlock?() }

    func leave() -> Single<Void> {
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
        agoraKit.disableAudio()
        agoraKit.disableVideo()
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
            localCameraOn = cameraOn
        } else {
            targetLocalCamera = cameraOn
            logger.trace("update local user status camera: \(cameraOn) to target")
        }
    }

    func updateLocalUser(micOn: Bool) {
        if isJoined.value {
            targetLocalMic = nil
            localAudioOn = micOn
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
         communication: Bool,
         isFrontMirror: Bool,
         isUsingFront: Bool,
         screenShareInfo: ShareScreenInfo?)
    {
        self.screenShareInfo = screenShareInfo
        self.isFrontMirror = isFrontMirror
        self.isUsingFront = isUsingFront
        localCameraOn = false
        localAudioOn = false
        super.init()

        let agoraKitConfig = AgoraRtcEngineConfig()
        agoraKitConfig.appId = appId
        agoraKitConfig.areaCode = .CN
        agoraKitConfig.channelProfile = .liveBroadcasting // 只用 liveBroadcasting 因为另一个模式会导致 airpodspro 2 无法使用 //communication ? .communication : .liveBroadcasting
        agoraKit = .sharedEngine(with: agoraKitConfig, delegate: self)

        agoraKit.setLogFile("") // set to default path
        agoraKit.setLogFilter(AgoraLogFilter.error.rawValue)
        agoraKit.setVideoEncoderConfiguration(encodeConfigWith(mirror: isFrontMirror))
        let captureConfig = AgoraCameraCapturerConfiguration()
        captureConfig.cameraDirection = isUsingFront ? .front : .rear
        agoraKit.setCameraCapturerConfiguration(captureConfig)

        // 启用针对多人通信场景的优化策略。
        agoraKit.setParameters("{\"che.audio.live_for_comm\": true}")
        // 4.2 用新的 api 开启多流
        // Agora 建议自定义的小流分辨率不超过 320 × 180 px，码率不超过 140 Kbps，且小流帧率不能超过大流帧率。
        let streamConfig = AgoraSimulcastStreamConfig()
        streamConfig.dimensions = CGSize(width: 320, height: 180)
        streamConfig.framerate = 5
        streamConfig.kBitrate = 140
        agoraKit.setDualStreamMode(.autoSimulcastStream, streamConfig: streamConfig)

        agoraKit.enableVideo()
        agoraKit.enableAudio()
        agoraKit.enableAudioVolumeIndication(200, smooth: 3, reportVad: false)
        // 初始化音视频传输
        _performAudioStateUpdate()
        _performCameraStateUpdate()
        // 初始化降噪
        _updateAINS()

        joinChannelBlock = { [weak self] in
            let canvas = AgoraRtcVideoCanvas()
            canvas.uid = uid
            canvas.renderMode = .hidden
            self?.localVideoCanvas = canvas

            logger.info("start join channel: \(channelId) uid: \(uid)")
            self?.agoraKit.joinChannel(byToken: token,
                                       channelId: channelId,
                                       info: nil,
                                       uid: uid, joinSuccess: { [weak self] msg, _, elapsed in
                                           logger.info("end join \(msg), elapsed \(elapsed)")
                                           self?.isJoined.accept(true)
                                       })
        }
        joinChannel()

        isJoined
            .filter { $0 }
            .subscribe(with: self, onNext: { weakSelf, _ in
                // TODO: Should force update.
                if let targetLocalMic = weakSelf.targetLocalMic {
                    weakSelf.updateLocalUser(micOn: targetLocalMic)
                }
                if let targetLocalCamera = weakSelf.targetLocalCamera {
                    weakSelf.updateLocalUser(cameraOn: targetLocalCamera)
                }
            })
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(onClassroomSettingNeedToggleCameraNotification), name: classroomSettingNeedToggleCameraNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onClassroomSettingNeedToggleFronMirrorNotification), name: classroomSettingNeedToggleFrontMirrorNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_updateAINS), name: ainsPreferenceUpdateNotificaton, object: nil)
    }
}

extension Rtc: AgoraRtcEngineDelegate {
    func rtcEngine(_: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        logger.warning("didOccurWarning \(warningCode)")
    }

    func rtcEngine(_: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        logger.error("didOccurError \(errorCode)")
    }

    func rtcEngineConnectionDidLost(_: AgoraRtcEngineKit) {
        logger.error("lost connection")
        errorPublisher.accept(.connectionLost)
    }

    func rtcEngine(_: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        switch state {
        case .disconnected, .connecting, .reconnecting, .failed:
            isJoined.accept(false)
        case .connected:
            isJoined.accept(true)
        @unknown default: break
        }
        logger.info("connectionChangedTo \(state) \(reason)")
    }

    func rtcEngine(_: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume _: Int) {
        for speaker in speakers {
            let strenth = CGFloat(speaker.volume) / 255
            if let p = micStrenths[speaker.uid] {
                p.accept(strenth)
            } else {
                micStrenths[speaker.uid] = .init()
                micStrenths[speaker.uid]?.accept(strenth)
            }
        }
    }

    func rtcEngine(_: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
        lastMileDelay.accept(Int(stats.lastmileDelay))
    }

    func rtcEngine(_: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        if uid == 0 {
            switch (rxQuality, txQuality) {
            case (.excellent, .excellent):
                networkStatusBehavior.accept(.excellent)
            case (.bad, _), (_, .bad):
                networkStatusBehavior.accept(.bad)
            case let (.unknown, s), let (s, .unknown):
                networkStatusBehavior.accept(s)
            default:
                networkStatusBehavior.accept(.good)
            }
        }
    }

    func rtcEngine(_: AgoraRtcEngineKit, didApiCallExecute _: Int, api _: String, result _: String) {}
    func rtcEngine(_: AgoraRtcEngineKit, didJoinChannel _: String, withUid _: UInt, elapsed _: Int) {}
    func rtcEngine(_: AgoraRtcEngineKit, didLeaveChannelWith _: AgoraChannelStats) {}

    func rtcEngine(_: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason _: AgoraUserOfflineReason) {
        if isScreenShareUid(uid: uid) {
            screenShareJoinBehavior.accept(false)
        }
    }

    func rtcEngine(_: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed _: Int) {
        if isScreenShareUid(uid: uid) {
            screenShareJoinBehavior.accept(true)
        }
    }

    func isScreenShareUid(uid: UInt) -> Bool {
        if let id = screenShareInfo?.uid, id == uid { return true }
        return false
    }
}

extension AgoraConnectionState: CustomStringConvertible {
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
        case .reasonConnecting: return "connecting"
        case .reasonJoinSuccess: return "joinSuccess"
        case .reasonInterrupted: return "interrupted"
        case .reasonBannedByServer: return "bannedByServer"
        case .reasonJoinFailed: return "joinFailed"
        case .reasonLeaveChannel: return "leaveChannel"
        case .reasonInvalidAppId: return "invalidAppId"
        case .reasonInvalidChannelName: return "invalidChannelName"
        case .reasonInvalidToken: return "invalidToken"
        case .reasonTokenExpired: return "tokenExpired"
        case .reasonRejectedByServer: return "rejectedByServer"
        case .reasonSettingProxyServer: return "settingProxyServer"
        case .reasonRenewToken: return "renewToken"
        case .reasonClientIpAddressChanged: return "clientIpAddressChanged"
        case .reasonKeepAliveTimeout: return "keepAliveTimeout"
        case .sameUidLogin: return "sameUidLogin"
        case .tooManyBroadcasters: return "tooManyBroadcasters"
        case .reasonRejoinSuccess: return "rejoinSuccess"
        case .reasonLost: return "lost"
        case .reasonEchoTest: return "echoTest"
        case .clientIpAddressChangedByUser: return "clientIpAddressChangedByUser"
        case .licenseValidationFailure: return "licenseValidationFailure"
        @unknown default: return "unknown \(rawValue)"
        }
    }
}
