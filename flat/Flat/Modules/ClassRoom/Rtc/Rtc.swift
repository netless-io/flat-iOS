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

class Rtc: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    private var joinChannelBlock: (()->Void)?
    
    // MARK: - Public
    func joinChannel() { joinChannelBlock?() }
    
    func leave() -> Single<Void> {
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        AgoraRtcEngineKit.destroy()
        return .just(())
    }
    
    private func observeApplicationLifeCycle() {
        UIApplication.rx.didEnterBackground
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                // Leave channle when enter background
                if let state = self?.agoraKit.getConnectionState(), state == .connected {
                    self?.agoraKit.leaveChannel(nil)
                    print("leave channel by application lifecycle")
                }
            })
            .disposed(by: rx.disposeBag)
        
        UIApplication.rx.willEnterForeground
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                // Rejoin channel when enter foreground
                if let state = self?.agoraKit.getConnectionState(), (state != .connected || state != .connecting || state != .reconnecting) {
                    self?.joinChannel()
                    print("rejoin channel by application lifecycle")
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    func updateRemoteUserStreamType(rtcUID: UInt, type: AgoraVideoStreamType) {
        agoraKit.setRemoteVideoStream(rtcUID, type: type)
    }
    
    func updateRemoteUser(rtcUID: UInt, cameraOn: Bool, micOn: Bool) {
        agoraKit.muteRemoteVideoStream(rtcUID, mute: !cameraOn)
        agoraKit.muteRemoteAudioStream(rtcUID, mute: !micOn)
    }
    
    func updateLocalUser(cameraOn: Bool) {
        agoraKit.enableLocalVideo(cameraOn)
        agoraKit.muteLocalVideoStream(!cameraOn)
        print("update local user status camera: \(cameraOn)")
    }
    
    func updateLocalUser(micOn: Bool) {
        agoraKit.enableLocalAudio(micOn)
        agoraKit.muteLocalAudioStream(!micOn)
        print("update local user status mic: \(micOn)")
    }
    
    func createOrFetchFromCacheCanvs(for uid: UInt) -> AgoraRtcVideoCanvas {
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
    var localVideoCanvas: AgoraRtcVideoCanvas!
    
    init(appId: String,
         channelId: String,
         token: String,
         uid: UInt) {
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
            
            self?.agoraKit.joinChannel(byToken: token,
                                       channelId: channelId,
                                       info: nil,
                                       uid: uid, joinSuccess: { msg, uid, elapsed in
                return
            })
        }
        joinChannel()
        observeApplicationLifeCycle()
    }
}

extension Rtc: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("rtc error \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute error: Int, api: String, result: String) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    }
}
