//
//  ReplayController.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/24.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

class ReplayViewController: UIViewController {
    let info: RecordDetailInfo

    init(info: RecordDetailInfo) {
        self.info = info
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupViews()
    }
    
    // MARK: - Private
    func setupViews() {
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(whiteboardView.snp.width).multipliedBy(ClassRoomLayoutRatioConfig.whiteboardRatio)
        }
        view.addSubview(videoScrollView)
        videoScrollView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(whiteboardView.snp.top)
        }
        videoScrollView.addSubview(whiteVideoView)
        
        overlay.attachTo(parent: view)
    }
    
    func setupPlayer() {
        initWhitePlayer()
    }
    
    func initWhitePlayer() {
        // Set up video player
        combinePlayer.delegate = self
        whiteVideoView.setAVPlayer(combinePlayer.nativePlayer)
        
        let videoSlice = info.recordInfo.first!
        let config = WhitePlayerConfig(room: info.whiteboardRoomUUID,
                                       roomToken: info.whiteboardRoomToken)
        let interval = videoSlice.endTime.timeIntervalSince(videoSlice.beginTime)
        config.beginTimestamp = NSNumber(value: videoSlice.beginTime.timeIntervalSince1970)
        config.duration = NSNumber(value: interval)
        overlay.updateDuration(interval)
        sdk.createReplayer(with: config, callbacks: self) { [weak self] success, player, error in
            self?.combinePlayer.whitePlayer = player
            self?.whitePlayer = player
            self?.whitePlayer.seek(toScheduleTime: 0)
        }
    }
    
    var whitePlayer: WhitePlayer!
    lazy var videoScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        view.isUserInteractionEnabled = false
        return view
    }()
    lazy var whiteVideoView = WhiteVideoView()
    lazy var combinePlayer = WhiteCombinePlayer(mediaUrl: info.recordInfo.first!.videoURL)
    
    lazy var sdk: WhiteSDK = {
        let sdkConfig = WhiteSdkConfiguration(app: Env().netlessAppId)
        return WhiteSDK(whiteBoardView: whiteboardView,
                       config: sdkConfig,
                       commonCallbackDelegate: self)
    }()
    
    lazy var overlay: ReplayOverlay = {
        let overlay = ReplayOverlay()
        overlay.delegate = self
        return overlay
    }()
}

extension ReplayViewController: ReplayOverlayDelegate {
    func replayOverlayDidClickClose(_ overlay: ReplayOverlay) {
        dismiss(animated: true, completion: nil)
    }
    
    func replayOverlayDidClickPlayOrPause(_ overlay: ReplayOverlay) {
        if overlay.isPause {
            combinePlayer.play()
            overlay.update(isPause: false)
        } else {
            combinePlayer.pause()
            overlay.update(isPause: true)
        }
        overlay.show()
    }
}

extension ReplayViewController: WhiteCombineDelegate {
    func combinePlayerEndBuffering() {
        if let track = combinePlayer.nativePlayer.currentItem?.tracks.first,
           let size = track.assetTrack?.naturalSize {
            let ratio = videoScrollView.frame.height / size.height
            let width = ratio * size.width
            whiteVideoView.frame = .init(origin: .zero, size: .init(width: width, height: videoScrollView.frame.height))
            videoScrollView.contentSize = whiteVideoView.bounds.size
        }
        combinePlayer.play()
        
        overlay.updateIsBuffering(false)
        overlay.update(isPause: false)
    }
    
    func combinePlayerStartBuffering() {
        overlay.updateIsBuffering(true)
    }
}

extension ReplayViewController: WhiteCommonCallbackDelegate {
    func sdkSetupFail(_ error: Error) {
        toast(error.localizedDescription)
    }
}

extension ReplayViewController: WhitePlayerEventDelegate {
    func phaseChanged(_ phase: WhitePlayerPhase) {
        combinePlayer.update(phase)
    }

    func loadFirstFrame() {
    }
    
    func stoppedWithError(_ error: Error) {
        toast(error.localizedDescription)
    }
    
    func scheduleTimeChanged(_ time: TimeInterval) {
        overlay.updateCurrentTime(time)
    }
}
