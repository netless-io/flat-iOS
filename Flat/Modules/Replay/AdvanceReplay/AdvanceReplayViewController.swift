//
//  AdvanceReplayViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation
import SyncPlayer
import Whiteboard

class AdvanceReplayViewController: UIViewController {
    let viewModel: AdvanceReplayViewModel
    
    // MARK: - LifeCycle
    init(viewModel: AdvanceReplayViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        // Select to first record
        if !viewModel.recordDetail.recordInfo.isEmpty {
            updateRecordIndex(0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewInset()
    }
    
    // MARK: - Private
    private func updateRecordIndex(_ index: Int) {
        viewModel.setupWhite(whiteboardView, index: index)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { weakSelf, record in
                weakSelf.updateWith(record.users)
                weakSelf.listen(to: record.player, duration: record.duration)
                weakSelf.updateSectionListButton()
                weakSelf.observe(userState: record.userState)
                weakSelf.updateScrollViewInset()
            }
            .disposed(by: rx.disposeBag)
    }
    
    let itemHeight: CGFloat = 144
    private func setupViews() {
        view.backgroundColor = .color(type: .background)
        view.addSubview(videoScrollView)
        videoScrollView.addSubview(videoItemsStackView)
        videoScrollView.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(itemHeight)
        }
        videoItemsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(videoScrollView.snp.bottom)
        }
        
        overlay.attachTo(parent: view)
    }
    
    var userStateDisposeBag: DisposeBag!
    private func observe(userState: Observable<[UInt: RoomUserStatus]>) {
        userStateDisposeBag = DisposeBag()
        userState
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { weakSelf, state in
                for (uid, userState) in state {
                    let itemView = weakSelf.itemViewForUid(uid)
                    let isRealMicOn = userState.isSpeak && userState.mic
                    let isRealCameraOn = userState.isSpeak && userState.camera
                    
                    itemView.showAvatar(!isRealCameraOn)
                    if let player = (itemView.videoContainerView.layer as? AVPlayerLayer)?.player {
                        player.isMuted = !isRealMicOn
                    }
                    itemView.isHidden = !userState.isSpeak
                }
                weakSelf.updateScrollViewInset()
            }
            .disposed(by: userStateDisposeBag)
    }
    
    var playerTimeObserver: Any?
    func listen(to player: SyncPlayer, duration: TimeInterval) {
        syncPlayer = player
        overlay.updateIsBuffering(true)
        player.addStatusListener { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .ready:
                self.overlay.update(isPause: true)
                self.overlay.updateIsBuffering(false)
            case .playing:
                self.overlay.update(isPause: false)
                self.overlay.updateIsBuffering(false)
            case .pause:
                self.overlay.update(isPause: true)
            case .buffering:
                self.overlay.updateIsBuffering(true)
            case .ended:
                self.overlay.update(isPause: true)
            case .error:
                self.overlay.update(isPause: false)
            }
        }
        
        overlay.updateDuration(floor(duration))
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: .init(value: 1000, timescale: 1000), queue: nil) { [weak self] t in
            guard let self = self else { return }
            self.overlay.updateCurrentTime(floor(t.seconds))
        }
    }
    
    func updateScrollViewInset() {
        let itemWidth = itemHeight / itemRatio
        let itemCount = CGFloat(videoItemsStackView.arrangedSubviews.filter { !$0.isHidden }.count)
        let estimateWidth = itemWidth * itemCount + (itemCount - 1) * videoItemsStackView.spacing
        if estimateWidth <= view.bounds.width {
            let margin = (view.bounds.width - estimateWidth) / 2
            videoScrollView.contentInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        } else {
            videoScrollView.contentInset = .zero
        }
    }
    
    func updateWith(_ userPlayers: [AdvanceReplayViewModel.ReplayUserPlayer]) {
        videoItemsStackView.arrangedSubviews.forEach {
            videoItemsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        for userPlayer in userPlayers {
            let itemView = itemViewForUid(userPlayer.user.rtcUID)
            if itemView.superview == nil {
                videoItemsStackView.addArrangedSubview(itemView)
            }
            remakeConstraintForItemView(view: itemView)
            refresh(view: itemView, user: userPlayer.user)
            refreshPlayer(view: itemView, player: userPlayer.player)
        }
    }
    
    let itemRatio: CGFloat = ClassRoomLayoutRatioConfig.rtcItemRatio
    func remakeConstraintForItemView(view: UIView) {
        view.snp.remakeConstraints { make in
            make.width.equalTo(videoItemsStackView.snp.height).multipliedBy(1 / self.itemRatio)
        }
    }
    
    func itemViewForUid(_ uid: UInt) -> RtcVideoItemView {
        let target = videoItemsStackView
            .arrangedSubviews
            .compactMap { $0 as? RtcVideoItemView }
            .first(where: { $0.uid == uid })
        if let target = target {
            return target
        } else {
            return RtcVideoItemView(uid: uid)
        }
    }
    
    func refresh(view: RtcVideoItemView, user: AdvanceReplayViewModel.ReplayUserInfo) {
        view.update(avatar: user.avatar)
        view.nameLabel.text = user.userName
        
        view.showMicVolum(false)
        view.showAvatar(!user.onStage)
        view.alwaysShowName = false
        view.silenceImageView.isHidden = true
        view.nameLabel.isHidden = true
    }
    
    func refreshPlayer(view: RtcVideoItemView, player: AVPlayer) {
        (view.videoContainerView.layer as? AVPlayerLayer)?.player = player
        (view.videoContainerView.layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
    }
    
    // MARK: - Lazy
    lazy var videoScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    lazy var videoItemsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [])
        view.axis = .horizontal
        return view
    }()
    
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    var syncPlayer: SyncPlayer?
    
    lazy var overlay: ReplayOverlay = {
        let overlay = ReplayOverlay()
        overlay.delegate = self
        overlay.toolStackView.addArrangedSubview(sectionListButton)
        sectionListButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        return overlay
    }()
    
    @objc func onClickSelectionList(_ sender: UIButton) {
        popoverViewController(viewController: selectionlistViewController, fromSource: sender)
        overlay.displayState = .showAlways
        selectionlistViewController.dismissHandler = { [weak self] in
            self?.overlay.displayState = .showDelayHide
        }
    }
    
    func updateSectionListButton() {
        let currentIndex = viewModel.currentIndex
        let sections = viewModel.recordDetail.recordInfo.enumerated().map { index, item -> (String, Bool) in
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let date = formatter.string(from: item.beginTime) + " ~ " + formatter.string(from: item.endTime)
            return (date, currentIndex == index)
        }
        selectionlistViewController.sections = sections
    }
    
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

extension AdvanceReplayViewController: ReplayOverlayDelegate {
    
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
        syncPlayer.seek(time: CMTime(seconds: seconds, preferredTimescale: time.timescale))
        overlay.show()
    }
    
    func replayOverlayDidClickForward(_ overlay: ReplayOverlay) {
        guard let syncPlayer = syncPlayer else { return }
        let time = syncPlayer.currentTime
        let seconds = min(time.seconds + 15, syncPlayer.totalTime.seconds)
        syncPlayer.seek(time: CMTime(seconds: seconds, preferredTimescale: time.timescale))
        overlay.show()
    }
    
    func replayOverlayDidClickSeekToPercent(_ overlay: ReplayOverlay, percent: Float) {
        guard let syncPlayer = syncPlayer else { return }
        let seconds = syncPlayer.totalTime.seconds * Double(percent)
        syncPlayer.seek(time: CMTime(seconds: seconds, preferredTimescale: syncPlayer.totalTime.timescale))
        overlay.show()
    }
}
