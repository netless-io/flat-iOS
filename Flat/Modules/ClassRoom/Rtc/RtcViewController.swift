//
//  RtcViewController1.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import Hero
import AgoraRtcKit
import RxCocoa

class RtcViewController: UIViewController {
    let viewModel: RtcViewModel
    
    let localUserCameraClick: PublishRelay<Void> = .init()
    let localUserMicClick: PublishRelay<Void> = .init()
    
    var localCameraOn = false
    var localMicOn = false
    
    var preferredMargin: CGFloat = 10 {
        didSet {
            guard preferredMargin != oldValue else { return }
            sync(direction: direction)
            updateScrollViewInset()
        }
    }
    
    let itemRatio: CGFloat = ClassRoomLayoutRatioConfig.rtcItemRatio
    
    func bindUsers(_ users: Driver<[RoomUser]>, withTeacherRtmUUID uuid: String) {
        let output = viewModel.transform(users: users, teacherRtmUUID: uuid)
        output.noTeacherViewHide
            .distinctUntilChanged()
            .do(afterNext: { [weak self] _ in
                self?.updateScrollViewInset()
            })
            .drive(noTeacherPlaceHolderView.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        output.nonLocalUsers
            .distinctUntilChanged({ i, j in
                return i.map { $0.user } == j.map { $0.user }
            })
            .drive(with: self, onNext: { weakSelf, values in
                let oldStackCount = weakSelf.videoItemsStackView.arrangedSubviews.count
                weakSelf.updateWith(nonTeacherValues: values)
                let newStackCount = weakSelf.videoItemsStackView.arrangedSubviews.count
                if newStackCount != oldStackCount {
                    weakSelf.cellMenuView.dismiss()
                }
                let existIds = values.map { $0.user.rtcUID }
                // If some user leave during preview, stop previewing
                if let user = weakSelf.previewingUser, !existIds.contains(user.rtcUID) {
                    weakSelf.previewViewController.showAvatar(url: user.avatarURL)
                }
                weakSelf.updateScrollViewInset()
            })
            .disposed(by: rx.disposeBag)
                
            
        output.localUserHide
            .do(afterNext: { [weak self] _ in
                self?.updateScrollViewInset()
            })
            .drive(localVideoItemView.rx.isHidden)
            .disposed(by: rx.disposeBag)
    }
    
    func bindLocalUser(_ user: Driver<RoomUser>) {
        let output = viewModel.transformLocalUser(user: user)
        
        output.user
            .drive(with: self, onNext: { weakSelf, user in
                weakSelf.localMicOn = user.status.isSpeak && user.status.mic
                weakSelf.localCameraOn = user.status.isSpeak && user.status.camera
                if !weakSelf.localVideoItemView.containsUserValue {
                    weakSelf.update(itemView: weakSelf.localVideoItemView, user: user)
                }
                weakSelf.cellMenuView.update(cameraOn: user.status.camera, micOn: user.status.mic)
            })
            .disposed(by: rx.disposeBag)

        output.mic
            .drive(localVideoItemView.silenceImageView.rx.isHidden)
            .disposed(by: rx.disposeBag)

        output.camera
            .drive(with: self, onNext: { weakSelf, value in
                weakSelf.localVideoItemView.showAvatar(!value.0)
                weakSelf.apply(canvas: value.1,
                               toView: value.0 ? weakSelf.localVideoItemView.videoContainerView : nil,
                               isLocal: true)
            })
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - LifeCycle
    init(viewModel: RtcViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
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
    }
    
    // MARK: - Direction
    fileprivate var direction: ClassRoomLayout.RtcDirection = .top {
        didSet {
            guard direction != oldValue else { return }
            sync(direction: direction)
        }
    }
    
    fileprivate func sync(direction: ClassRoomLayout.RtcDirection) {
        let marginInset = preferredMargin * 2
        switch direction {
        case .right:
            videoItemsStackView.axis = .vertical
            videoItemsStackView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: preferredMargin, bottom: 0, right: preferredMargin))
                make.width.equalTo(self.view).offset(-marginInset)
            }
        case .top:
            videoItemsStackView.axis = .horizontal
            videoItemsStackView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: preferredMargin, left: 0, bottom: preferredMargin, right: 0))
                make.height.equalTo(self.view).offset(-marginInset)
            }
        }
        videoItemsStackView.arrangedSubviews.forEach { remakeConstraintForItemView(view: $0, direction: direction) }
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .commonBG
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(videoItemsStackView)
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        sync(direction: direction)
    }
    
    func update(itemView: RtcVideoItemView, user: RoomUser) {
        itemView.heroID = nil
        itemView.update(avatar: user.avatarURL)
        if user.isOnline {
            itemView.nameLabel.text = user.name
            itemView.nameLabel.isHidden = true
        } else {
            itemView.nameLabel.text = "\(user.name) (\(localizeStrings("offline")))"
            itemView.nameLabel.isHidden = false
        }
        itemView.silenceImageView.isHidden = user.status.mic
        itemView.containsUserValue = true
        itemView.alwaysShowName = !user.isOnline
    }
    
    func refresh(view: RtcVideoItemView,
                 user: RoomUser,
                 canvas: AgoraRtcVideoCanvas,
                 isLocal: Bool) {
        update(itemView: view, user: user)
        view.showAvatar(!user.status.camera)
        
        viewModel.rtc.updateRemoteUserStreamType(rtcUID: user.rtcUID, type: viewModel.userThumbnailStream(user.rtcUID))
        apply(canvas: canvas,
              toView: user.status.camera ? view.videoContainerView : nil,
              isLocal: isLocal)
    }
    
    func remakeConstraintForItemView(view: UIView, direction: ClassRoomLayout.RtcDirection) {
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
    
    func updateWith(nonTeacherValues values: [(user: RoomUser, canvas: AgoraRtcVideoCanvas)]) {
        for value in values {
            let itemView = itemViewForUid(value.user.rtcUID)
            if itemView.superview == nil {
                videoItemsStackView.addArrangedSubview(itemView)
                itemView.tapHandler = { [weak self] view in
                    self?.respondToVideoItemVideoTap(view: view, isLocal: false)
                }
                remakeConstraintForItemView(view: itemView, direction: direction)
            }
            itemView.isHidden = false
            refresh(view: itemView,
                    user: value.user,
                    canvas: value.canvas,
                    isLocal: false)
        }
        var existIds = values.map { $0.user.rtcUID }
        // Local users
        existIds.append(0)
        for view in videoItemsStackView.arrangedSubviews {
            if let itemView = view as? RtcVideoItemView {
                if !existIds.contains(itemView.uid){
                    itemView.removeFromSuperview()
                    videoItemsStackView.removeArrangedSubview(itemView)
                }
            }
        }
        updateScrollViewInset()
    }
    
    func updateScrollViewInset() {
        switch direction {
        case.right:
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
        }
    }
    
    func apply(canvas: AgoraRtcVideoCanvas, toView view: UIView?, isLocal: Bool) {
        if canvas.view == view { return }
        canvas.view = view
        if isLocal {
            viewModel.rtc.agoraKit.setupLocalVideo(canvas)
        } else {
            viewModel.rtc.agoraKit.setupRemoteVideo(canvas)
        }
    }
    
    func itemViewForUid(_ uid: UInt) -> RtcVideoItemView {
        if let view = videoItemsStackView.arrangedSubviews.compactMap({ v -> RtcVideoItemView? in
            v as? RtcVideoItemView
        }).first(where: { $0.uid == uid }) {
            return view
        } else {
            return RtcVideoItemView(uid: uid)
        }
    }
    
    // MARK: - Preview
    var previewingUser: RoomUser?
    func preview(view: RtcVideoItemView) {
        let uid = view.uid
        guard let user = viewModel.userFetch(uid) else { return }
        previewingUser = user
        logger.trace("start preview \(uid)")
        view.nameLabel.isHidden = true
        let heroId = uid.description
        view.heroID = heroId
        if user.status.camera {
            previewViewController.showVideoPreview()
            
            if viewModel.localUserRegular(uid) {
                viewModel.rtc.localVideoCanvas.view = previewViewController.contentView
                viewModel.rtc.agoraKit.setupLocalVideo(viewModel.rtc.localVideoCanvas)
            } else {
                let canvas = viewModel.rtc.createOrFetchFromCacheCanvas(for: uid)
                canvas.view = previewViewController.contentView
                // 放大为大流
                viewModel.rtc.updateRemoteUserStreamType(rtcUID: uid, type: .high)
                viewModel.rtc.agoraKit.setupRemoteVideo(canvas)
            }
            previewViewController.contentView.heroID = heroId
            previewViewController.avatarContainer.heroID = nil
            previewViewController.contentView.heroModifiers = [.useNoSnapshot]
        } else {
            previewViewController.showAvatar(url: user.avatarURL)
            previewViewController.avatarContainer.heroID = heroId
            previewViewController.contentView.heroID = nil
        }
        
        previewViewController.hero.isEnabled = true
        previewViewController.hero.modalAnimationType = .none
        previewViewController.view.heroModifiers = [.fade, .useNoSnapshot]
        present(previewViewController, animated: true, completion: nil)
    }
    
    func endPreviewing(UID: UInt) {
        guard let user = viewModel.userFetch(UID) else { return }
        let isLocal = viewModel.localUserRegular(UID)
        if let view = videoItemsStackView.arrangedSubviews.first(where: { [weak self] in
            guard let self = self else { return false }
            guard let view = $0 as? RtcVideoItemView else { return false }
            if isLocal {
                return self.viewModel.localUserRegular(view.uid)
            } else {
                return view.uid == UID
            }
        }) as? RtcVideoItemView {
            refresh(view: view,
                    user: user,
                    canvas: isLocal ? viewModel.rtc.localVideoCanvas : viewModel.rtc.createOrFetchFromCacheCanvas(for: UID),
                    isLocal: isLocal)
        }
    }
    
    lazy var previewViewController: RtcPreviewViewController = {
        let vc = RtcPreviewViewController()
        vc.dismissHandler = { [weak self] in
            guard let self = self,
                  let previewingUser = self.previewingUser else { return }
            self.endPreviewing(UID: previewingUser.rtcUID)
        }
        vc.modalPresentationStyle = .fullScreen
        return vc
    }()
    
    // MARK: - Lazy View
    lazy var noTeacherPlaceHolderView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "teach_not_showup"))
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    func respondToVideoItemVideoTap(view: RtcVideoItemView, isLocal: Bool) {
        videoItemsStackView.arrangedSubviews.forEach {
            if let itemView = $0 as? RtcVideoItemView {
                if !itemView.alwaysShowName {
                    itemView.nameLabel.isHidden = true
                }
            }
        }
        view.nameLabel.isHidden = !view.nameLabel.isHidden
        
        if isLocal {
            cellMenuView.show(fromSource: view, direction: .bottom, inset: .init(top: -10, left: -10, bottom: -10, right: -10))
            cellMenuView.update(cameraOn: localCameraOn, micOn: localMicOn)
            cellMenuView.dismissHandle = { [weak view] in
                view?.nameLabel.isHidden = true
            }
            cellMenuView.clickHandler = { [weak self] op in
                guard let self = self else { return }
                switch op {
                case .camera:
                    self.localUserCameraClick.accept(())
                case .mic:
                    self.localUserMicClick.accept(())
                case .scale:
                    self.preview(view: view)
                }
            }
        } else {
            self.preview(view: view)
        }
    }
    
    lazy var localVideoItemView: RtcVideoItemView = {
        let view = RtcVideoItemView(uid: 0)
        view.tapHandler = { [weak self] in
            self?.respondToVideoItemVideoTap(view: $0, isLocal: true)
        }
        return view
    }()
    
    lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    lazy var videoItemsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [noTeacherPlaceHolderView, localVideoItemView])
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.spacing = 8
        return view
    }()
    
    lazy var cellMenuView: RtcCellPopMenuView = {
        let view = RtcCellPopMenuView()
        return view
    }()
}
