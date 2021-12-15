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
    let isTeacher: Bool
    
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
            let ownderId = roomOwnerRtmUUID
            let displayUsers = users
                .do(onNext: { [weak self] users in
                    self?.teacher = users.first(where: { $0.rtmUUID == ownderId })
                })
                .map { $0.filter { user in user.rtmUUID != ownderId } }
                .asDriver(onErrorJustReturn: [])
            
            displayUsers.drive(tableView.rx.items(cellIdentifier: cellIdentifier, cellType: RoomUserTableViewCell.self)) { [weak self] index, item, cell in
                self?.config(cell: cell, user: item)
            }
            .disposed(by: rx.disposeBag)
            
            if !isTeacher {
                stopInteractingButton.isHidden = true
            } else {
                users.map {
                    !($0.contains(where: { $0.status.isRaisingHand || $0.status.isSpeak }))
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
        self.isTeacher = roomOwnerRtmUUID == userUUID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset = .init(top: topView.bounds.height, left: 0, bottom: 8, right: 0)
        preferredContentSize = .init(width: 360, height: UIScreen.main.bounds.height * 0.67)
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
        view.backgroundColor = .whiteBG
        view.addSubview(tableView)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(34)
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func config(cell: RoomUserTableViewCell, user: RoomUser) {
        let isTeacher = user.rtmUUID == roomOwnerRtmUUID
        cell.disconnectButton.isHidden = true
        cell.raiseHandButton.isHidden = true
        if isTeacher {
            cell.nameLabel.text = user.name + "(\(NSLocalizedString("Teach", comment: "")))"
            cell.statusLabel.text = nil
        } else {
            cell.nameLabel.text = user.name
            if user.status.isRaisingHand {
                cell.statusLabel.text = "(\(NSLocalizedString("Raised Hand", comment: "")))"
                cell.statusLabel.textColor = .controlSelected
                cell.raiseHandButton.isHidden = false
            } else if user.status.isSpeak {
                cell.statusLabel.text = "(\(NSLocalizedString("Interacting", comment: "")))"
                cell.statusLabel.textColor = .init(hexString: "#9FDF76")
                cell.disconnectButton.isHidden = false
            } else {
                cell.statusLabel.text = nil
            }
        }
        cell.avatarImageView.kf.setImage(with: user.avatarURL)
        cell.cameraButton.isSelected = user.status.camera
        cell.micButton.isSelected = user.status.mic
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
        view.backgroundColor = .whiteBG
        let topLabel = UILabel(frame: .zero)
        topLabel.text = NSLocalizedString("User List", comment: "")
        topLabel.textColor = .text
        topLabel.font = .systemFont(ofSize: 12, weight: .medium)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(RoomUserTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.rowHeight = 55
        return view
    }()
    
    lazy var teacherLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    lazy var stopInteractingButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitleColor(.text, for: .normal)
        btn.setTitle(NSLocalizedString("Stop Interacting", comment: ""), for: .normal)
        btn.contentEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12)
        btn.layer.borderColor = UIColor.borderColor.cgColor
        btn.layer.borderWidth = 1 / UIScreen.main.scale
        return btn
    }()
    
    lazy var teachAvatarImageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 15
        return view
    }()
    
    lazy var teacherHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .whiteBG
        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        view.addSubview(teachAvatarImageView)
        view.addSubview(teacherLabel)
        view.addSubview(stopInteractingButton)
        teachAvatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        teacherLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(50)
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
}

extension ClassRoomUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = teacher {
            return 48
        } else {
            return .leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let teacher = teacher {
            teachAvatarImageView.kf.setImage(with: teacher.avatarURL)
            teacherLabel.text = teacher.name + " (" + NSLocalizedString("Teacher", comment: "") + ")"
            return teacherHeaderView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
