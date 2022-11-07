//
//  AdvanceMixReplayViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Whiteboard
import RxSwift
import SyncPlayer

class AdvanceMixReplayViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return traitCollection.hasCompact ? .landscapeRight : .landscape
    }
    override var prefersStatusBarHidden: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    
    let viewModel: AdvanceMixReplayViewModel
    var rtcPlayer: AVPlayer?
    var syncPlayer: SyncPlayer?
    
    // MARK: - LifeCycle
    init(viewModel: AdvanceMixReplayViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        syncPlayer?.destroy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        // Select to first record
        if !viewModel.recordDetail.recordInfo.isEmpty {
            updateRecordIndex(0)
            setupSectionList()
        }
    }
    
    // MARK: - Private
    private func updateRecordIndex(_ index: Int, autoPlay: Bool = true) {
        syncPlayer?.destroy()
        syncPlayer = nil
        rtcPlayer = nil
        playerTimeObserver = nil
        whiteboardView?.removeFromSuperview()
        whiteboardView = nil
        
        let newWhiteView = WhiteBoardView()
        newWhiteView.isUserInteractionEnabled = false
        whiteboardView = newWhiteView
        view.insertSubview(newWhiteView, belowSubview: videoScrollView)
        newWhiteView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(videoScrollView.snp.bottom)
        }
        
        overlay.displayState = .showDelayHide
        overlay.updateIsBuffering(true)
        viewModel.setupWhite(newWhiteView, index: index)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { weakSelf, record in
                weakSelf.listen(to: record.player, duration: record.duration)
                weakSelf.setup(forRtcPlayer: record.rtcPlayer)
                if autoPlay {
                    weakSelf.syncPlayer?.play()
                }
            }
            .disposed(by: rx.disposeBag)
    }
    
    func setup(forRtcPlayer player: AVPlayer) {
        rtcPlayer = player
        // Loop for asset loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak player, weak self] in
            guard
                let self = self,
                let capturePlayer = player,
                let rtc = self.rtcPlayer,
                rtc === capturePlayer,
                let track = capturePlayer.currentItem?.tracks.first,
                let size = track.assetTrack?.naturalSize
            else {
                if let p = player, let s = self {
                    s.setup(forRtcPlayer: p)
                }
                return
            }
            
            let ratio = self.videoScrollView.frame.height / size.height
            let width = ratio * size.width
            if width.isNaN {
                self.toast("Can't load video info, please try again later")
                return
            }
            self.videoPreview.frame = .init(origin: .zero, size: .init(width: width, height: self.videoScrollView.bounds.height))
            self.videoScrollView.contentSize = self.videoPreview.bounds.size
            (self.videoPreview.layer as? AVPlayerLayer)?.player = capturePlayer
            (self.videoPreview.layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
        }
    }
    
    var isSeeking = false
    var playerTimeObserver: Any?
    func listen(to player: SyncPlayer, duration: TimeInterval) {
        syncPlayer = player
        player.addStatusListener { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .ready:
                if self.isSeeking { return }
                self.overlay.updateIsBuffering(false)
                self.overlay.update(isPause: true)
            case .playing:
                self.overlay.update(isPause: false)
                self.overlay.updateIsBuffering(false)
            case .pause:
                self.overlay.update(isPause: true)
            case .buffering:
                self.overlay.updateIsBuffering(true)
            case .ended:
                self.overlay.update(isPause: true)
                self.overlay.showAlways()
            case .error:
                self.overlay.updateIsBuffering(false)
                self.overlay.update(isPause: false)
            }
        }
        
        overlay.updateDuration(floor(duration))
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: .init(value: 1000, timescale: 1000), queue: nil) { [weak self] t in
            guard let self = self else { return }
            if self.isSeeking { return }
            self.overlay.updateCurrentTime(floor(t.seconds))
        }
    }
    
    func setupSectionList() {
        let currentIndex = viewModel.currentIndex
        let sections = viewModel.recordDetail.recordInfo.enumerated().map { index, item -> (String, Bool) in
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let date = formatter.string(from: item.beginTime) + " ~ " + formatter.string(from: item.endTime)
            return (date, currentIndex == index)
        }
        selectionlistViewController.sections = sections
    }
    
    private func setupViews() {
        view.backgroundColor = .color(type: .background)
        view.addSubview(videoScrollView)
        overlay.attachTo(parent: view)
        
        videoScrollView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(singleRecordHeight)
        }
    }
    
    // MARK: - Action
    @objc func onClickSelectionList(_ sender: UIButton) {
        popoverViewController(viewController: selectionlistViewController, fromSource: sender)
        overlay.displayState = .showAlways
        selectionlistViewController.dismissHandler = { [weak self] in
            self?.overlay.displayState = .showDelayHide
        }
    }
    
    // MARK: - Lazy
    lazy var videoScrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInsetAdjustmentBehavior = .never
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.addSubview(videoPreview)
        return view
    }()
    
    lazy var videoPreview = VideoPreviewView()
    
    var whiteboardView: WhiteBoardView?
    
    lazy var overlay: ReplayOverlay = {
        let overlay = ReplayOverlay()
        overlay.delegate = self
        overlay.toolStackView.addArrangedSubview(sectionListButton)
        sectionListButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        return overlay
    }()
    
    lazy var sectionListButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let img = UIImage(systemName: "list.number", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("List", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(onClickSelectionList), for: .touchUpInside)
        return btn
    }()
    
    lazy var selectionlistViewController: RecordSelectionListViewController = {
        let vc = RecordSelectionListViewController()
        vc.clickHandler = { [weak self] index in
            guard let self = self else { return }
            guard self.viewModel.currentIndex != index else { return }
            self.updateRecordIndex(index)
        }
        return vc
    }()
}

extension AdvanceMixReplayViewController: ReplayOverlayDelegate {
    func replayOverlayDidClickClose(_ overlay: ReplayOverlay) {
        dismiss(animated: true, completion: nil)
    }
    
    func replayOverlayDidClickPlayOrPause(_ overlay: ReplayOverlay) {
        guard let syncPlayer = syncPlayer else { return }
        switch syncPlayer.status {
        case .pause, .ready:
            syncPlayer.play()
        case .ended:
            syncPlayer.seek(time: .zero) { [weak syncPlayer] success in
                if success {
                    syncPlayer?.play()
                }
            }
        default:
            syncPlayer.pause()
        }
        overlay.show()
    }
    
    func replayOverlayDidClickBackward(_ overlay: ReplayOverlay) {
        guard let syncPlayer = syncPlayer else { return }
        let time = syncPlayer.currentTime
        let seconds = max(time.seconds - 15, 0)
        seekTo(seconds)
    }
    
    func replayOverlayDidClickForward(_ overlay: ReplayOverlay) {
        guard let syncPlayer = syncPlayer else { return }
        let time = syncPlayer.currentTime
        let seconds = min(time.seconds + 15, syncPlayer.totalTime.seconds)
        seekTo(seconds)
    }
    
    func replayOverlayDidClickSeekToPercent(_ overlay: ReplayOverlay, percent: Float) {
        guard let syncPlayer = syncPlayer else { return }
        let seconds = syncPlayer.totalTime.seconds * Double(percent)
        guard !seconds.isNaN else { return }
        seekTo(seconds)
    }
    
    func seekTo(_ seconds: TimeInterval) {
        guard let syncPlayer = syncPlayer else { return }
        let cmTime = CMTime(seconds: seconds, preferredTimescale: syncPlayer.totalTime.timescale)
        
        isSeeking = true
        // 这里的 buffer 和 普通的 buffer 会冲突。需要注意一下
        overlay.updateIsBuffering(true)
        overlay.updateCurrentTime(seconds)
        syncPlayer.seek(time: cmTime) { [weak overlay, weak self] success in
            if success {
                overlay?.updateIsBuffering(false)
                self?.isSeeking = false
            }
        }
        overlay.show()
    }
}
