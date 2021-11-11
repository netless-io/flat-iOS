//
//  RTCViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import AgoraRtcKit
import Hero

protocol RtcViewControllerDelegate: AnyObject {
    func rtcViewControllerDidMeetError(_ controller: RtcViewController, error: Error)
    
    func rtcViewControllerDidClickMic(_ controller: RtcViewController, forUser user: RoomUser)
    
    func rtcViewControllerDidClickCamera(_ controller: RtcViewController, forUser user: RoomUser)
}

/// Manage only video/audio connections by self,
/// while control states and user list from outside
class RtcViewController: UIViewController {
    weak var delegate: RtcViewControllerDelegate?
    var agoraKit: AgoraRtcEngineKit!
    let token: String
    let channelId: String
    let rtcUid: UInt
    let noTeachCellIdentifier = "noTeachCellIdentifier"
    let cellIdentifier = "RtcVideoCollectionViewCell"
    var shouldShowNoTeach = false {
        didSet {
            collectionView.reloadData()
        }
    }
    /// Append user or remove user should manage this variable directely outside
    var users: [RoomUser] = [] {
        didSet {
            updateUsersRtcStatus()
            // TODO: diff
            collectionView.performBatchUpdates {
                self.collectionView.reloadData()
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            } completion: { _ in
                
            }
            cellMenuView.dismiss()
        }
    }
    
    // MARK: - Public
    func leave() {
        agoraKit.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
    
    // TODO: show a disconnected view when join failed
    func joinChannel() {
        agoraKit.joinChannel(byToken: token, channelId: channelId, info: nil, uid: rtcUid, options: .init())
    }
    
    // MARK: - LifeCycle
    init(token: String,
         channelId: String,
         rtcUid: UInt) {
        self.token = token
        self.channelId = channelId
        self.rtcUid = rtcUid
        super.init(nibName: nil, bundle: nil)
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Env().agoraAppId, delegate: self)
        self.agoraKit.setLogFile("") // set to default path
        self.agoraKit.setLogFilter(AgoraLogFilter.error.rawValue)
        
        // 大流720P视频
        let config = AgoraVideoEncoderConfiguration(size: .init(width: 1280, height: 720), frameRate: .fps15, bitrate: 1130, orientationMode: .adaptative)
        agoraKit.setVideoEncoderConfiguration(config)
        // 各发流端在加入频道前或者后，都可以调用 enableDualStreamMode 方法开启双流模式。
        self.agoraKit.enableDualStreamMode(true)
        // 启用针对多人通信场景的优化策略。
        self.agoraKit.setParameters("{\"che.audio.live_for_comm\": true}")
        // Agora 建议自定义的小流分辨率不超过 320 × 180 px，码率不超过 140 Kbps，且小流帧率不能超过大流帧率。
        self.agoraKit.setParameters("{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":5,\"bitRate\":140}}")
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // TODO: Update with permission
        agoraKit.enableVideo()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topMargin: CGFloat = 10
        let minSideMargin: CGFloat = 11
        let spacing: CGFloat = 8
        let itemWidth: CGFloat = 112
        let itemHeight: CGFloat = 84
        layout.itemSize = .init(width: itemWidth, height: itemHeight)
        layout.sectionInset = .init(top: topMargin, left: minSideMargin, bottom: topMargin, right: minSideMargin)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        let itemCount: CGFloat = CGFloat(collectionView(collectionView, numberOfItemsInSection: 0))
        let estimateWidth = itemWidth * itemCount + (itemCount - 1) * spacing
        if estimateWidth <= view.bounds.width {
            var new = layout.sectionInset
            let margin = (view.bounds.width - estimateWidth) / 2
            new.left = margin
            new.right = margin
            layout.sectionInset = new
        }
        collectionView.reloadSections([0])
    }
    
    // MARK: - Action
    var panStartIndexPath: IndexPath?
    @objc func onPan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            let locaion = pan.location(in: collectionView)
            if let responderView = collectionView.hitTest(locaion, with: nil) {
                if responderView is UICollectionView {
                    return
                }
                var cell = responderView.superview
                while cell != nil {
                    if let cell = cell as? RtcVideoCollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
                        if let presented = presentedViewController {
                            presented.dismiss(animated: false) {
                                self.panStartIndexPath = indexPath
                                self.preview(cell: cell, indexPath: indexPath)
                            }
                        } else {
                            self.panStartIndexPath = indexPath
                            self.preview(cell: cell, indexPath: indexPath)
                        }
                        return
                    } else {
                        cell = cell?.superview
                    }
                }
            }
        case .changed:
            guard panStartIndexPath != nil else { return }
            let y = pan.translation(in: view).y
            let screenHeight = UIScreen.main.bounds.height
            if y >= 0 {
                Hero.shared.update(y / screenHeight )
            } else {
                Hero.shared.update(0.01)
            }
        default:
            guard panStartIndexPath != nil else { return }
            let y = pan.translation(in: view).y
            let velocityY = pan.velocity(in: view).y
            let screenHeight = UIScreen.main.bounds.height
            let total = y + velocityY
            if total / screenHeight >= 0.5 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
            panStartIndexPath = nil
        }
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
    
    func configCellEndDisplay(_ cell: RtcVideoCollectionViewCell, user: RoomUser) {
        
    }
    
    func updateUsersRtcStatus() {
        for user in users {
            let status = user.status
            if user.rtcUID == rtcUid {
                // Self
                agoraKit.enableLocalAudio(status.mic)
                agoraKit.enableLocalVideo(status.camera)
                agoraKit.muteLocalAudioStream(!status.mic)
                agoraKit.muteLocalVideoStream(!status.camera)
//                if status.camera {
//                    videoStreamingUID.insert(rtcUid)
//                } else {
//                    videoStreamingUID.remove(rtcUid)
//                }
            } else {
                agoraKit.setRemoteVideoStream(user.rtcUID, type: .low)
                // Others
                agoraKit.muteRemoteVideoStream(user.rtcUID, mute: !status.camera)
                agoraKit.muteRemoteAudioStream(user.rtcUID, mute: !status.mic)
            }
        }
    }
    
    func applyVideoCanvasTo(view: UIView?,
                            uid: UInt,
                            camera: Bool) {
        if uid == rtcUid {
            localVideoCanvas.view = camera ? view : nil
            agoraKit.setupLocalVideo(localVideoCanvas)
        } else {
            let canvas = createOrFetchFromCacheCanvs(for: uid)
            canvas.view = camera ? view : nil
            agoraKit.setupRemoteVideo(canvas)
        }
    }
    
    func config(cell: RtcVideoCollectionViewCell, user: RoomUser) {
        func showAvatar(_ show: Bool) {
            cell.largeAvatarImageView.isHidden = !show
            cell.effectView.isHidden = !show
            cell.avatarImageView.isHidden = !show
        }
        cell.heroID = nil
        cell.update(avatar: user.avatarURL)
        cell.nameLabel.text = user.name
        cell.nameLabel.isHidden = true
        cell.silenceImageView.isHidden = user.status.mic
        if user.status.camera {
            showAvatar(false)
        } else {
            showAvatar(true)
        }

        // Do not update canvas when presenting preview
        // Update at not presented or being dismissed
        if previewViewController.presentingViewController == nil || previewViewController.isBeingDismissed {
            applyVideoCanvasTo(view: cell.videoContainerView,
                               uid: user.rtcUID,
                               camera: user.status.camera)
//                               camera: user.status.camera && videoStreamingUID.contains(user.rtcUID))
        }
    }
    
    func userAt(_ indexPath: IndexPath) -> RoomUser? {
        if shouldShowNoTeach, indexPath.row > 0 {
            return users[indexPath.row - 1]
        } else {
            return users[indexPath.row]
        }
    }
    // MARK: - Lazy
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    lazy var localVideoCanvas: AgoraRtcVideoCanvas = {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = rtcUid
        canvas.renderMode = .hidden
        return canvas
    }()
//
//    lazy var videoStreamingUID: Set<UInt> = [] {
//        didSet {
//            collectionView.reloadData()
//        }
//    }
    
    lazy var remoteCanvas: [UInt: AgoraRtcVideoCanvas] = [:]
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .init(hexString: "#F7F9FB")
        view.register(RtcVideoCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        view.register(RtcNoTeachCollectionViewCell.self, forCellWithReuseIdentifier: noTeachCellIdentifier)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    lazy var previewViewController: RtcPreviewViewController = {
        let vc = RtcPreviewViewController()
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }
        vc.modalPresentationStyle = .fullScreen
        return vc
    }()
    
    lazy var cellMenuView: RtcCellPopMenuView = {
        let view = RtcCellPopMenuView()
        return view
    }()
}

extension RtcViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        shouldShowNoTeach ? users.count + 1 : users.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if shouldShowNoTeach, indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: noTeachCellIdentifier, for: indexPath) as! RtcNoTeachCollectionViewCell
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! RtcVideoCollectionViewCell
        if let user = userAt(indexPath) {
            config(cell: cell, user: user)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // TODO: Model is removed before UI
    }
    
    func preview(cell: RtcVideoCollectionViewCell, indexPath: IndexPath) {
        // Dismiss some popover
        guard let user = userAt(indexPath) else { return }
        let id = "preview\(user.rtcUID)"
        cell.nameLabel.isHidden = true
        
        cell.heroID = id
        if user.status.camera {
            previewViewController.contentView.isHidden = false
            previewViewController.avatarContainer.isHidden = true
            
            if user.rtcUID == rtcUid {
                localVideoCanvas.view = previewViewController.contentView
                agoraKit.setupLocalVideo(localVideoCanvas)
            } else {
                let canvas = createOrFetchFromCacheCanvs(for: user.rtcUID)
                canvas.view = previewViewController.contentView
                // 将订阅的一路视频流设为大流，其它路视频流均设置为小流。
                agoraKit.setRemoteVideoStream(user.rtcUID, type: .high)
                agoraKit.setupRemoteVideo(canvas)
            }
            previewViewController.contentView.heroID = id
            previewViewController.avatarContainer.heroID = nil
            previewViewController.contentView.heroModifiers = [.useNoSnapshot]
        } else {
            previewViewController.contentView.isHidden = true
            previewViewController.avatarContainer.isHidden = false
            
            previewViewController.avatarImageView.kf.setImage(with: user.avatarURL)
            previewViewController.largeAvatarImageView.kf.setImage(with: user.avatarURL)
            
            previewViewController.avatarContainer.heroID = id
            previewViewController.contentView.heroID = nil
        }
        previewViewController.hero.isEnabled = true
        previewViewController.hero.modalAnimationType = .none
        previewViewController.view.heroModifiers = [.fade, .useNoSnapshot]
        present(previewViewController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? RtcVideoCollectionViewCell {
            collectionView.visibleCells.forEach({
                if $0 !== cell {
                    ($0 as? RtcVideoCollectionViewCell)?.nameLabel.isHidden = true
                }
            })
            cell.nameLabel.isHidden = !cell.nameLabel.isHidden
            
            guard let user = userAt(indexPath),
                  user.rtcUID == rtcUid else { return }
            let status = user.status
            cellMenuView.show(fromSouce: cell,
                              direction: .bottom,
                              inset: .init(top: -10, left: -10, bottom: -10, right: -10))
            cellMenuView.update(cameraOn: status.camera, micOn: status.mic)
            cellMenuView.dismissHandle = { [weak cell] in
                cell?.nameLabel.isHidden = true
            }
            cellMenuView.clickHandler = { [weak self] op in
                guard let self = self else { return }
                switch op {
                case .camera:
                    self.delegate?.rtcViewControllerDidClickCamera(self, forUser: user)
                case .mic:
                    self.delegate?.rtcViewControllerDidClickMic(self, forUser: user)
                case .scale:
                    self.preview(cell: cell, indexPath: indexPath)
                }
            }
        }
    }
}

extension RtcViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        delegate?.rtcViewControllerDidMeetError(self, error: "rtc error \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didApiCallExecute error: Int, api: String, result: String) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    }
    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
//        switch state {
//        case .stopped:
//            videoStreamingUID.remove(uid)
//        case .starting:
//            videoStreamingUID.insert(uid)
//        default:
//            return
//        }
//        print("rtc remote changed \(uid), now \(videoStreamingUID)")
//    }
}
