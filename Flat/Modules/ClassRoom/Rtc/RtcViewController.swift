//
//  RtcViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AgoraRtcKit
import AVFAudio
import Hero
import Lottie
import MetalKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit
import ViewDragger

struct FreeDraggingUser: Equatable {
    let uid: UInt
    let rect: CGRect
}

enum RtcDirection {
    case top
    case right
}

enum DraggingPossibleTargetView {
    case minimal(UIView)
    case grid
}

typealias UserCanvasDraggingResult = (uid: UInt, rect: CGRect)

let defaultDraggingScaleOfCanvas = CGFloat(0.4)
let minDraggingScaleOfCanvas = CGFloat(0.25)

class RtcViewController: UIViewController {
    let viewModel: RtcViewModel
    weak var draggingCanvasProvider: VideoDraggingCanvasProvider!

    let userCameraClick: PublishRelay<String> = .init()
    let userMicClick: PublishRelay<String> = .init()
    let whiteboardClick: PublishRelay<RoomUser> = .init()
    let rewardsClick: PublishRelay<String> = .init()
    let muteAllClick: PublishRelay<Void> = .init()
    let resetLayoutClick: PublishRelay<UInt> = .init()

    var preferredMargin: CGFloat = 0 {
        didSet {
            guard preferredMargin != oldValue else { return }
            sync(direction: direction)
            updateScrollViewInset()
        }
    }

    let itemRatio: CGFloat = ClassRoomLayoutRatioConfig.rtcItemRatio
    let layoureRefreshTrigger: PublishRelay<Void> = .init()
    let userMinimalDragging: PublishRelay<UInt> = .init()
    let userCanvasDragging: PublishRelay<UserCanvasDraggingResult> = .init()
    let userTap: PublishRelay<UInt> = .init()
    let doublePublisher: PublishRelay<UInt> = .init()
    var isGridNow = false
    var rtcMinimalSize: CGSize = .zero
    var draggers: [UInt: ViewDragger] = [:]

    var draggingPossibleTargetView: DraggingPossibleTargetView? {
        willSet {
            stopTargetViewHint()
        }
    }

    func bindUsers(_ users: Driver<[RoomUser]>) {
        viewModel
            .trans(users)
            .drive(with: self, onNext: { weakSelf, values in
                weakSelf.updateWith(values)
            })
            .disposed(by: rx.disposeBag)

        viewModel.tranformLayoutInfo(.init(users: users.asObservable(),
                                           refreshTrigger: layoureRefreshTrigger.asDriverOnErrorJustComplete()))
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self) { ws, output in
                ws.processLayoutOutput(output)
            }
            .disposed(by: rx.disposeBag)

        if viewModel.canUpdateLayout {
            viewModel.tranformLayoutTask(.init(
                userTap: userTap.asDriverOnErrorJustComplete(),
                userDoubleTap: doublePublisher.asDriverOnErrorJustComplete(),
                userMinimalDragging: userMinimalDragging.asDriverOnErrorJustComplete(),
                userCanvasDragging: userCanvasDragging.asDriverOnErrorJustComplete(),
                resetLayoutTap: resetLayoutClick.asDriverOnErrorJustComplete()
            ))
            .subscribe()
            .disposed(by: rx.disposeBag)
        }
    }

    // MARK: - LifeCycle

    init(viewModel: RtcViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        viewModel.rtc.isJoined.asDriver()
            .drive(with: self, onNext: { weakSelf, joined in
                if joined {
                    weakSelf.stopActivityIndicator()
                } else {
                    weakSelf.showActivityIndicator()
                }
            })
            .disposed(by: rx.disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        direction = view.bounds.width > view.bounds.height ? .top : .right
        updateScrollViewInset()
        layoureRefreshTrigger.accept(())
    }

    // MARK: - Direction

    var direction: RtcDirection = .top {
        didSet {
            guard direction != oldValue else { return }
            sync(direction: direction)
        }
    }

    fileprivate func sync(direction: RtcDirection) {
        switch direction {
        case .right:
            videoItemsStackView.axis = .vertical
            line.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.top.bottom.equalToSuperview()
                make.width.equalTo(commonBorderWidth)
            }
        case .top:
            videoItemsStackView.axis = .horizontal
            line.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.left.right.equalToSuperview()
                make.height.equalTo(commonBorderWidth)
            }
        }
        videoItemsStackView.arrangedSubviews.forEach {
            remakeConstraintForItemView(view: $0, direction: direction)
        }
    }

    // MARK: - Private

    func setupViews() {
        view.backgroundColor = .color(type: .background)
        view.addSubview(mainScrollView)
        view.addSubview(line)
        mainScrollView.addSubview(videoItemsStackView)
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        sync(direction: direction)
    }

    func processLayoutOutput(_ op: RtcViewModel.LayoutUsersInfo) {
        let expandCount = op.expandUsers.count
        isGridNow = !op.expandUsers.isEmpty
        if isGridNow {
            draggingCanvasProvider.onStartGridPreview()
        } else {
            draggingCanvasProvider.onEndGridPreview()
        }

        op.freeDraggingUsers.forEach {
            let contentView = itemViewForUid($0.uid).contentView
            move(contentView: contentView, toScaledRect: $0.rect)
            contentView.superview?.bringSubviewToFront(contentView)
        }
        op.minimalUsers.forEach {
            minimal(view: itemViewForUid($0))
        }
        op.expandUsers.enumerated().forEach { index, uid in
            expand(view: itemViewForUid(uid), userIndex: index, totalCount: expandCount)
        }
    }

    var volumesDisposeBag = DisposeBag()
    func update(itemView: RtcVideoItemView,
                user: RoomUser,
                showAvatar: Bool,
                volumeBag: DisposeBag)
    {
        itemView.heroID = nil
        itemView.update(avatar: user.avatarURL)
        itemView.backLabel.text = user.name
        itemView.contentView.nameLabel.text = user.name
        itemView.contentView.offlineMaskLabel.isHidden = user.isOnline
        itemView.contentView.silenceImageView.isHidden = user.status.mic
        itemView.contentView.showVolume = user.status.mic
        itemView.contentView.showAvatar = showAvatar
        itemView.contentView.controlView.update(cameraOn: user.status.camera,
                                                micOn: user.status.mic,
                                                whiteboardOn: user.status.whiteboard,
                                                whiteboardHide: !viewModel.canUpdateWhiteboard(user.rtcUID),
                                                rewardsHide: !viewModel.canSendRewards(user.rtcUID),
                                                resetLayoutHide: !viewModel.canResetLayout(user.rtcUID),
                                                muteAllHide: !viewModel.canMuteAll(user.rtcUID))

        if user.status.mic {
            viewModel.strenthFor(uid: user.rtcUID)
                .asDriver(onErrorJustReturn: 0)
                .drive(with: itemView) { wi, strenth in
                    wi.contentView.micStrenth = strenth
                }
                .disposed(by: volumeBag)
        }
    }

    func remakeConstraintForItemView(view: UIView, direction: RtcDirection) {
        switch direction {
        case .right:
            view.snp.remakeConstraints { make in
                make.height.equalTo(videoItemsStackView.snp.width).multipliedBy(self.itemRatio)
            }
        case .top:
            view.snp.remakeConstraints { make in
                make.width.equalTo(videoItemsStackView.snp.height).multipliedBy(1 / self.itemRatio)
            }
        }
    }

    func updateWith(_ values: [RtcViewModel.RTCUserOutput]) {
        // Reset voluem spy
        volumesDisposeBag = DisposeBag()

        for value in values {
            let itemView = itemViewForUid(value.user.rtcUID)
            if itemView.superview == nil {
                videoItemsStackView.addArrangedSubview(itemView)
                remakeConstraintForItemView(view: itemView, direction: direction)
            }
            itemView.isHidden = false
            update(itemView: itemView,
                   user: value.user,
                   showAvatar: !value.user.status.camera || !value.user.isOnline,
                   volumeBag: volumesDisposeBag)

            // Move canvas to container
            if itemView.contentView.videoContainerView.subviews.isEmpty {
                let cv = value.canvasView
                itemView.contentView.videoContainerView.addSubview(cv)
            }
        }
        let speakingIds = values.filter(\.user.status.isSpeak).map(\.user.rtcUID)
        videoItemsStackView
            .arrangedSubviews
            .compactMap { $0 as? RtcVideoItemView }
            .filter { !speakingIds.contains($0.uid) }
            .forEach { remove(view: $0) }
        updateScrollViewInset()
    }

    func remove(view: RtcVideoItemView) {
        view.removeFromSuperview()
        videoItemsStackView.removeArrangedSubview(view)
        view.contentView.removeFromSuperview()
        draggers.removeValue(forKey: view.uid)
    }

    func updateScrollViewInset() {
        switch direction {
        case .right:
            let widthInset = preferredMargin * 2
            let itemWidth = view.bounds.width - widthInset
            let itemHeight = itemWidth * itemRatio
            let itemCount = CGFloat(videoItemsStackView.arrangedSubviews.filter { !$0.isHidden }.count)
            let estimateHeight = itemHeight * itemCount + (itemCount - 1) * videoItemsStackView.spacing
            if estimateHeight <= view.bounds.height {
                let margin = (view.bounds.height - estimateHeight) / 2
                mainScrollView.contentInset = UIEdgeInsets(top: margin, left: 0, bottom: margin, right: 0)
            } else {
                mainScrollView.contentInset = .zero
            }
            rtcMinimalSize = .init(width: itemWidth, height: itemHeight)
            let itemsSize = CGSize(width: itemWidth, height: estimateHeight)
            videoItemsStackView.frame = .init(origin: .init(x: preferredMargin, y: 0), size: itemsSize)
            mainScrollView.contentSize = itemsSize
        case .top:
            let heightInset = preferredMargin * 2
            let itemHeight = view.bounds.height - heightInset
            let itemWidth = itemHeight / itemRatio
            let itemCount = CGFloat(videoItemsStackView.arrangedSubviews.filter { !$0.isHidden }.count)
            let estimateWidth = itemWidth * itemCount + (itemCount - 1) * videoItemsStackView.spacing
            if estimateWidth <= view.bounds.width {
                let margin = (view.bounds.width - estimateWidth) / 2
                mainScrollView.contentInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
            } else {
                mainScrollView.contentInset = .zero
            }
            rtcMinimalSize = .init(width: itemWidth, height: itemHeight)
            let itemsSize = CGSize(width: estimateWidth, height: itemHeight)
            videoItemsStackView.frame = .init(origin: .init(x: preferredMargin, y: 0), size: itemsSize)
            mainScrollView.contentSize = itemsSize
        }
    }

    // MARK: - Fetch ContentView

    func itemViewForUid(_ uid: UInt) -> RtcVideoItemView {
        if let view = videoItemsStackView.arrangedSubviews.compactMap({ v -> RtcVideoItemView? in
            v as? RtcVideoItemView
        }).first(where: { $0.uid == uid }) {
            return view
        } else {
            let view = RtcVideoItemView(uid: uid)
            if viewModel.canUpdateLayout {
                let dragger = ViewDragger(animationView: view.contentView,
                                          targetDraggingView: draggingCanvasProvider.getDraggingView(),
                                          animationType: .frame)
                dragger.delegate = self
                dragger.panGesture.delegate = self
                draggers[uid] = dragger

                let pinchDelegate = UIPinchGestureRecognizer(target: self, action: #selector(onPinch))
                view.contentView.addGestureRecognizer(pinchDelegate)
                pinchDelegate.delegate = self
            }

            view.tapHandler = { [weak self] view in
                self?.respondToVideoItemVideoTap(view: view)
            }
            view.doubleTapHandler = { [weak self] view in
                self?.doublePublisher.accept(view.uid)
            }
            view.contentView.controlView.clickHandler = { [weak self, weak view] type in
                guard let self else { return }
                view?.contentView.showControlViewAndHideAfter(delay: 3)
                guard let user = self.viewModel.userFetch(uid) else { return }
                let uuid = user.rtmUUID
                switch type {
                case .mic:
                    self.userMicClick.accept(uuid)
                case .camera:
                    self.userCameraClick.accept(uuid)
                case .whiteboard:
                    self.whiteboardClick.accept(user)
                case .rewards:
                    self.rewardAnimation(uid: uid)
                    self.rewardsClick.accept(uuid)
                case .resetLayout:
                    self.resetLayoutClick.accept(uid)
                case .muteAll:
                    self.muteAllClick.accept(())
                }
            }
            return view
        }
    }

    lazy var rewardPlayer: AVAudioPlayer? = {
        guard let rewardAudioPath = Bundle.main.url(forResource: "reward", withExtension: "mp3") else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: rewardAudioPath)
            player.prepareToPlay()
            return player
        }
        catch {
            logger.error("play reward audio fail \(error)")
            return nil
        }
    }()

    func rewardAnimation(uid: UInt) {
        guard let window = view.window else { return }
        rewardPlayer?.play()
        let animationView = LottieAnimationView(name: "reward")
        window.addSubview(animationView)
        let windowSize = window.bounds.size
        animationView.center = .init(x: windowSize.width / 2, y: windowSize.height / 2)
        animationView.bounds = .init(origin: .zero, size: windowSize.applying(.init(scaleX: 0.5, y: 0.5)))
        animationView.isUserInteractionEnabled = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.play { [weak animationView, weak self] _ in
            guard let self else {
                animationView?.removeFromSuperview()
                return
            }
            guard let animationView else { return }
            let userItemView = self.itemViewForUid(uid).contentView
            let frameInWindow = window.convert(userItemView.bounds, from: userItemView)
            UIView.animate(withDuration: 0.5) {
                animationView.frame = frameInWindow
            }
            UIView.animate(withDuration: 0.5, delay: 0.5) {
                animationView.alpha = 0
            } completion: { _ in
                animationView.removeFromSuperview()
            }
        }
    }

    // MARK: - Lazy View

    func respondToVideoItemVideoTap(view: RtcItemContentView) {
        if viewModel.canUpdateDeviceState(view.uid) {
            view.toggleControlViewDisplay()
        }
        view.superview?.bringSubviewToFront(view)
        userTap.accept(view.uid)
    }

    lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    lazy var videoItemsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [])
        view.axis = .horizontal
        return view
    }()

    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = .borderColor
        return view
    }()
}

extension RtcViewController: ViewDraggerDelegate {
    func travelAnimationDidRecoverWith(travelAnimation _: ViewDragger, view _: UIView, travelState _: TravelState) {}

    func travelAnimationDidStartWith(travelAnimation _: ViewDragger, view _: UIView, travelState _: TravelState) {}

    func travelAnimationDidCancelWith(travelAnimation _: ViewDragger, view _: UIView, travelState _: TravelState) {}

    func travelAnimationDidUpdateProgress(travelAnimation _: ViewDragger, view _: UIView, travelState _: TravelState, progress _: CGFloat) {}

    func travelAnimationDidCompleteWith(travelAnimation _: ViewDragger, view _: UIView, travelState _: TravelState) {}

    // MARK: - Free Dragging

    func travelAnimationStartFreeDragging(travelAnimation _: ViewDragger, view: UIView) {
        view.superview?.bringSubviewToFront(view) // Just for local display
        if let contentView = view as? RtcItemContentView {
            contentView.finishCurrentAnimation()
            contentView.isDragging = true
            contentView.updateRtcSnapShot() // Snapshot on local dragging.

            let isPartInScrollView = isContentView(contentView, partIn: mainScrollView)
            if isPartInScrollView {
                draggingPossibleTargetView = .grid
            } else {
                draggingPossibleTargetView = .minimal(itemViewForUid(contentView.uid))
            }

            if isPartInScrollView { // Means dragging from rtc top view.
                let currentScale = contentView.bounds.width / draggingCanvasProvider.getDraggingView().bounds.width
                let scale = defaultDraggingScaleOfCanvas / currentScale
                let startFrame = contentView.frame
                let width = startFrame.width * scale
                let height = width * ClassRoomLayoutRatioConfig.rtcPreviewRatio
                let xOffset = (width - startFrame.width) / 2
                let yOffset = (height - startFrame.height) / 2
                contentView.frame = .init(x: startFrame.origin.x - xOffset,
                                          y: startFrame.origin.y - yOffset,
                                          width: width,
                                          height: height)
                if ClassRoomLayoutRatioConfig.rtcPreviewRatio != ClassRoomLayoutRatioConfig.rtcItemRatio {
                    contentView.tempDisplaySnapshot()
                }
            }
        }
    }

    func travelAnimationCancelFreeDragging(travelAnimation _: ViewDragger, view: UIView) {
        if let contentView = view as? RtcItemContentView {
            contentView.isDragging = false
            contentView.endRtcSnapShot()
        }
    }

    func travelAnimationFreeDraggingUpdate(travelAnimation _: ViewDragger, view: UIView) {
        let contentView = view as! RtcItemContentView
        if let draggingPossibleTargetView {
            switch draggingPossibleTargetView {
            case .grid:
                let isPartInScrollView = isContentView(contentView, partIn: mainScrollView)
                if !isPartInScrollView {
                    startTargetViewHint(withAnimationView: contentView)
                } else {
                    let isLeaveOverQuarterScrollView = isContentView(contentView, leaveOverQuarter: mainScrollView)
                    if isLeaveOverQuarterScrollView {
                        startTargetViewHint(withAnimationView: contentView)
                    } else {
                        stopTargetViewHint()
                    }
                }
            case .minimal:
                let isTotalInScrollView = isContentView(contentView, totalInScrollView: mainScrollView)
                if isTotalInScrollView {
                    startTargetViewHint(withAnimationView: contentView)
                } else {
                    let isCoverOverQuarterScrollView = isContentView(contentView, coverOverQuarter: mainScrollView)
                    if isCoverOverQuarterScrollView {
                        startTargetViewHint(withAnimationView: contentView)
                    } else {
                        stopTargetViewHint()
                    }
                }
            }
        }
    }

    func travelAnimationEndFreeDragging(travelAnimation _: ViewDragger, view: UIView, velocity: CGPoint) {
        guard let contentView = view as? RtcItemContentView else { return }
        let itemView = itemViewForUid(contentView.uid)
        contentView.isDragging = false
        contentView.endRtcSnapShot()

        stopTargetViewHint()

        let isTotalInScrollView = isContentView(contentView, totalInScrollView: mainScrollView)
        let isPartOfViewInScrollView = isContentView(contentView, partIn: mainScrollView)
        let isCoverOverQuarterScrollView = isContentView(contentView, coverOverQuarter: mainScrollView)
        let isLeaveOverQuarterScrollView = isContentView(contentView, leaveOverQuarter: mainScrollView)

        if isTotalInScrollView { // View is on the top
            endFreeDraggingViewToMinimal(itemView)
        } else if isPartOfViewInScrollView { // Part of view is on the edge
            let isVelocityToMinimal: Bool = direction == .top ? (abs(velocity.y) > abs(velocity.x) && velocity.y < -66) : (abs(velocity.x) > abs(velocity.y) && velocity.x > 66)
            let isVelocityToCanvas: Bool = direction == .top ? (abs(velocity.y) > abs(velocity.x) && velocity.y > 66) : (abs(velocity.x) > abs(velocity.y) && velocity.x < -66)
            if isVelocityToMinimal {
                endFreeDraggingViewToMinimal(itemView)
            } else if isVelocityToCanvas {
                endFreeDraggingViewToCanvas(itemView, endingVelocity: velocity)
            } else if let draggingPossibleTargetView {
                switch draggingPossibleTargetView {
                case .grid:
                    if isLeaveOverQuarterScrollView {
                        endFreeDraggingViewToCanvas(itemView, endingVelocity: velocity)
                    } else {
                        endFreeDraggingViewToMinimal(itemView)
                    }
                case .minimal:
                    if isCoverOverQuarterScrollView {
                        endFreeDraggingViewToMinimal(itemView)
                    } else {
                        endFreeDraggingViewToCanvas(itemView, endingVelocity: velocity)
                    }
                }
            } else { // Drag to edge
                endFreeDraggingViewToCanvas(itemView, endingVelocity: velocity)
            }
        } else {
            endFreeDraggingViewToCanvas(itemView, endingVelocity: velocity)
        }
    }

    // MARK: - End free dragging

    func endFreeDraggingViewToMinimal(_ itemView: RtcVideoItemView) {
        userMinimalDragging.accept(itemView.uid)
        minimal(view: itemView)
    }

    func endFreeDraggingViewToCanvas(_ itemView: RtcVideoItemView, endingVelocity: CGPoint) {
        let uid = itemView.uid
        let contentView = itemView.contentView
        let canvas = draggingCanvasProvider.getDraggingView()
        let frameInCanvas = contentView.convert(contentView.bounds, to: canvas)

        func scaled(_ rect: CGRect) -> CGRect {
            CGRect(x: rect.origin.x / canvas.bounds.width,
                   y: rect.origin.y / canvas.bounds.height,
                   width: rect.width / canvas.bounds.width,
                   height: rect.height / canvas.bounds.height)
        }

        var adjustFrame = frameInCanvas

        // Adding velocity (Ignore low velocity)
        let velocityXOffset = endingVelocity.x / 5
        let velocityYOffset = endingVelocity.y / 5

        let targetOriginX = adjustFrame.origin.x + velocityXOffset
        let targetOriginY = adjustFrame.origin.y + velocityYOffset

        // Keep in canvas rect
        adjustFrame.origin.x = min(max(0, targetOriginX), canvas.bounds.width - frameInCanvas.width)
        adjustFrame.origin.y = min(max(0, targetOriginY), canvas.bounds.height - frameInCanvas.height)

        if !isGridNow {
            move(contentView: contentView, toScaledRect: scaled(adjustFrame))
        }
        userCanvasDragging.accept((uid, scaled(adjustFrame)))
    }
}
