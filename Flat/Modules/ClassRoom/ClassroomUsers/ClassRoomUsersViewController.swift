//
//  ClassRoomUsersViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/17.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ClassRoomUsersViewController: UIViewController {
    let cellIdentifier = "cellIdentifier"
    
    let userUUID: String
    let roomOwnerRtmUUID: String
    let isOwner: Bool
    
    let disconnectTap: PublishRelay<RoomUser> = .init()
    let raiseHandTap: PublishRelay<RoomUser> = .init()
    let cameraTap: PublishRelay<RoomUser> = .init()
    let micTap: PublishRelay<RoomUser> = .init()
    let stopInteractingTap: PublishRelay<Void> = .init()
    
    var teacher: RoomUser? {
        didSet {
            tableView.reloadData()
        }
    }
    
    var users: Observable<[RoomUser]>? {
        didSet {
            guard let users = users else {
                return
            }
            let ownerId = roomOwnerRtmUUID
            let displayUsers = users
                .do(onNext: { [weak self] users in
                    self?.teacher = users.first(where: { $0.rtmUUID == ownerId })
                })
                .map { $0.filter { user in user.rtmUUID != ownerId } }
                .asDriver(onErrorJustReturn: [])
            
            displayUsers.drive(tableView.rx.items(cellIdentifier: cellIdentifier, cellType: RoomUserTableViewCell.self)) { [weak self] index, item, cell in
                self?.config(cell: cell, user: item)
            }
            .disposed(by: rx.disposeBag)
            
            if !isOwner {
                stopInteractingButton.isHidden = true
            } else {
                users.map {
                    $0.first(where: {
                        $0.rtmUUID != ownerId && ($0.status.isSpeak || $0.status.isRaisingHand )
                    }).map { _ in false } ?? true
                }.asDriver(onErrorJustReturn: true)
                    .drive(stopInteractingButton.rx.isHidden)
                    .disposed(by: rx.disposeBag)
            }
        }
    }
    
    // MARK: - LifeCycle
    init(userUUID: String,
         roomOwnerRtmUUID: String) {
        self.roomOwnerRtmUUID = roomOwnerRtmUUID
        self.userUUID = userUUID
        self.isOwner = roomOwnerRtmUUID == userUUID
        super.init(nibName: nil, bundle: nil)
        
        preferredContentSize = .init(width: greatWindowSide / 2, height: 560)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }
    
    // MARK: - Private
    func bind() {
        stopInteractingButton.rx.tap
            .bind(to: stopInteractingTap)
            .disposed(by: rx.disposeBag)
        
        tableView
            .rx.setDelegate(self)
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        view.backgroundColor = .classroomChildBG
        view.addSubview(tableView)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(40)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    func config(cell: RoomUserTableViewCell, user: RoomUser) {
        cell.cameraButton.isHidden = true
        cell.micButton.isHidden = true
        
        let isCellUserTeacher = user.rtmUUID == roomOwnerRtmUUID
        cell.disconnectButton.isHidden = true
        cell.raiseHandButton.isHidden = true
        if isCellUserTeacher {
            cell.nameLabel.text = user.name + "(\(localizeStrings("Teach")))"
            cell.statusLabel.text = nil
        } else {
            cell.nameLabel.text = user.name
            
            if user.status.isSpeak {
                if user.isOnline {
                    cell.statusLabel.text = "(\(localizeStrings("Interacting")))"
                    cell.statusLabel.textColor = .init(hexString: "#9FDF76")
                } else {
                    cell.statusLabel.text = "(\(localizeStrings("offline")))"
                    cell.statusLabel.textColor = .systemRed
                }
                cell.cameraButton.isHidden = false
                cell.micButton.isHidden = false
                cell.disconnectButton.isHidden = !(isOwner || user.rtmUUID == userUUID)
            } else if user.status.isRaisingHand {
                cell.statusLabel.text = "(\(localizeStrings("Raised Hand")))"
                cell.statusLabel.textColor = .color(type: .primary)
                cell.raiseHandButton.isHidden = !isOwner
            } else {
                cell.statusLabel.text = nil
            }
        }
        cell.avatarImageView.kf.setImage(with: user.avatarURL)
        cell.cameraButton.isSelected = user.status.camera
        cell.micButton.isSelected = user.status.mic
        
        let isUserSelf = user.rtmUUID == userUUID
        cell.cameraButton.isEnabled = user.status.camera || isUserSelf
        cell.micButton.isEnabled = user.status.mic || isUserSelf
        cell.clickHandler = { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .camera:
                self.cameraTap.accept(user)
            case .mic:
                self.micTap.accept(user)
            case .disconnect:
                self.disconnectTap.accept(user)
            case .raiseHand:
                self.raiseHandTap.accept(user)
            }
        }
    }
    
    // MARK: - Lazy
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .classroomChildBG
        let topLabel = UILabel(frame: .zero)
        topLabel.text = localizeStrings("User List")
        topLabel.textColor = .color(type: .text, .strong)
        topLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(40)
        }
        
        let leftIcon = UIImageView()
        leftIcon.setTraitRelatedBlock { iconView in
            iconView.image = UIImage(named: "users")?.tintColor(.color(type: .text, .strong).resolveDynamicColorPatchiOS13With(iconView.traitCollection))
        }
        leftIcon.contentMode = .scaleAspectFit
        view.addSubview(leftIcon)
        leftIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(8)
        }
        view.addLine(direction: .bottom, color: .borderColor)
        return view
    }()
    
    lazy var teacherLabel: UILabel = {
        let label = UILabel()
        label.textColor = .color(type: .text)
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    lazy var stopInteractingButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.setTitle(localizeStrings("Stop Interacting"), for: .normal)
        btn.contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
        btn.layer.borderColor = UIColor.borderColor.cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        return btn
    }()
    
    lazy var teachAvatarImageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 16
        return view
    }()
    
    lazy var teacherHeaderView: UITableViewHeaderFooterView = {
        let view = UITableViewHeaderFooterView()
        view.contentView.backgroundColor = .classroomChildBG
        view.addLine(direction: .bottom, color: .borderColor, inset: .init(top: 0, left: 16, bottom: 0, right: 16))
        view.addSubview(teachAvatarImageView)
        view.addSubview(teacherLabel)
        view.addSubview(stopInteractingButton)
        teachAvatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        teacherLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(56)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(stopInteractingButton.snp.left).offset(-10)
        }
        stopInteractingButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }
        stopInteractingButton.layer.cornerRadius = 14
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .classroomChildBG
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(RoomUserTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.rowHeight = 56
        if #available(iOS 15.0, *) {
            // F apple
            view.sectionHeaderTopPadding = 0
        } else {
        }
        return view
    }()
}

extension ClassRoomUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = teacher {
            return 56
        } else {
            return .leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let teacher = teacher {
            teachAvatarImageView.kf.setImage(with: teacher.avatarURL)
            teacherLabel.text = teacher.name + " (" + localizeStrings("Teacher") + ")"
            return teacherHeaderView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
