//
//  AdvanceMixReplayViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import SyncPlayer
import Whiteboard

class MixReplayViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.hasCompact ? .landscapeRight : .landscape
    }

    override var prefersStatusBarHidden: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    let viewModel: MixReplayViewModel
    var rtcPlayer: AVPlayer?
    var syncPlayer: SyncPlayer?

    // MARK: - LifeCycle

    init(viewModel: MixReplayViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

        let newWhiteView: WhiteBoardView
        if let customBundlePath = Bundle.main.path(forResource: "whiteboard_rebuild", ofType: "bundle"),
           let customBundle = Bundle(path: customBundlePath),
           let indexPath = customBundle.path(forResource: "index", ofType: "html")
        {
            newWhiteView = WhiteBoardView(customUrl: URL(fileURLWithPath: indexPath).absoluteString)
        } else {
            newWhiteView = WhiteBoardView()
        }
        
        newWhiteView.setTraitRelatedBlock { v in
            v.backgroundColor = .color(type: .background).resolvedColor(with: v.traitCollection)
        }
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
                let self,
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

    var isDraging = false
    var isSeeking = false
    var playerTimeObserver: Any?
    func listen(to player: SyncPlayer, duration: TimeInterval) {
        syncPlayer = player
        player.addStatusListener { [weak self] status in
            guard let self else { return }
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
            guard let self else { return }
            if self.isSeeking { return }
            if self.isDraging { return }
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
        let img = UIImage(systemName: "list.number", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        btn.setImage(img, for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(onClickSelectionList), for: .touchUpInside)
        return btn
    }()

    lazy var selectionlistViewController: RecordSelectionListViewController = {
        let vc = RecordSelectionListViewController()
        vc.clickHandler = { [weak self] index in
            guard let self else { return }
            guard self.viewModel.currentIndex != index else { return }
            self.updateRecordIndex(index)
        }
        return vc
    }()

    var drakSeekingPercent: Float?
}

extension MixReplayViewController: ReplayOverlayDelegate {
    func replayOverlayDidClickClose(_: ReplayOverlay) {
        dismiss(animated: true, completion: nil)
    }

    func replayOverlayDidClickPlayOrPause(_ overlay: ReplayOverlay) {
        guard let syncPlayer else { return }
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

    func replayOverlayDidClickBackward(_: ReplayOverlay) {
        guard let syncPlayer else { return }
        let time = syncPlayer.currentTime
        let seconds = max(time.seconds - 15, 0)
        seekTo(seconds)
    }

    func replayOverlayDidClickForward(_: ReplayOverlay) {
        guard let syncPlayer else { return }
        let time = syncPlayer.currentTime
        let seconds = min(time.seconds + 15, syncPlayer.totalTime.seconds)
        seekTo(seconds)
    }

    func replayOverlayDidClickSeekToPercent(_: ReplayOverlay, percent: Float) {
        guard let syncPlayer else { return }
        let seconds = syncPlayer.totalTime.seconds * Double(percent)
        guard !seconds.isNaN else { return }
        seekTo(seconds)
    }

    func replayOverlayDidUpdatePanGestureState(_ overlay: ReplayOverlay, sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            overlay.apply(displayState: .showAlways)
            isDraging = true
        case .changed:
            let view = overlay.progressView
            let x = sender.location(in: view).x
            let percent = Float(x / view.bounds.width)
            let boundsPercent = min(max(0, percent), 1)
            drakSeekingPercent = boundsPercent
            overlay.updateCurrentTime(overlay.duration * Double(boundsPercent))
        case .ended:
            if let p = drakSeekingPercent {
                seekTo(Double(p) * overlay.duration)
            }
            drakSeekingPercent = nil
            isDraging = false
            overlay.apply(displayState: .showDelayHide)
        case .failed, .cancelled:
            if let s = syncPlayer?.currentTime.seconds {
                overlay.updateCurrentTime(s)
            }
            drakSeekingPercent = nil
            isDraging = false
            overlay.apply(displayState: .showDelayHide)
        default:
            return
        }
    }

    func seekTo(_ seconds: TimeInterval) {
        guard let syncPlayer else { return }
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
