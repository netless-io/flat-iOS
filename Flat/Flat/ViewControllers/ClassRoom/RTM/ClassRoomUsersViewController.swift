//
//  ClassRoomUsersViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

protocol ClassRoomUsersViewControllerDelegate: AnyObject {
    func classRoomUsersViewControllerDidClickDisConnect(_ vc: ClassRoomUsersViewController, user: RoomUser)
    
    func classRoomUsersViewControllerDidClickRaiseHand(_ vc: ClassRoomUsersViewController, user: RoomUser)
    
    func classRoomUsersViewControllerDidClickCamera(_ vc: ClassRoomUsersViewController, user: RoomUser)
    
    func classRoomUsersViewControllerDidClickMic(_ vc: ClassRoomUsersViewController, user: RoomUser)
    
    func classRoomUsersViewControllerDidClickStopInteracting(_ vc: ClassRoomUsersViewController)
}

class ClassRoomUsersViewController: PopOverDismissDetectableViewController {
    let cellIdentifier = "cellIdentifier"

    let userUUID: String
    let roomOwnerRtmUUID: String
    let isTeacher: Bool
    
    weak var delegate: ClassRoomUsersViewControllerDelegate?
    
    var users: [RoomUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var displayUsers: [RoomUser] { users.filter({ $0.rtmUUID != roomOwnerRtmUUID })}
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset = .init(top: topView.bounds.height, left: 0, bottom: 8, right: 0)
        preferredContentSize = .init(width: 360, height: UIScreen.main.bounds.height * 0.67)
    }
    
    // MARK: - Action
    @objc func onClickIntercting() {
        delegate?.classRoomUsersViewControllerDidClickStopInteracting(self)
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .white
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
    
    func getTeacherIfExist() -> RoomUser? {
        users.first(where: { $0.rtmUUID == roomOwnerRtmUUID })
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
                self.delegate?.classRoomUsersViewControllerDidClickCamera(self, user: user)
            case .mic:
                self.delegate?.classRoomUsersViewControllerDidClickMic(self, user: user)
            case .disconnect:
                self.delegate?.classRoomUsersViewControllerDidClickDisConnect(self, user: user)
            case .raiseHand:
                self.delegate?.classRoomUsersViewControllerDidClickRaiseHand(self, user: user)
            }
        }
    }
    
    // MARK: - Lazy
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        let topLabel = UILabel(frame: .zero)
        topLabel.text = NSLocalizedString("Users List", comment: "")
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
        view.delegate = self
        view.dataSource = self
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
        btn.addTarget(self, action: #selector(onClickIntercting), for: .touchUpInside)
        return btn
    }()
    
    lazy var teacherHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        view.addSubview(teacherLabel)
        view.addSubview(stopInteractingButton)
        teacherLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(stopInteractingButton.snp.left).offset(-10)
        }
        stopInteractingButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }
        stopInteractingButton.layer.cornerRadius = 14
        return view
    }()
}

extension ClassRoomUsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RoomUserTableViewCell
        config(cell: cell, user: displayUsers[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = getTeacherIfExist() {
            return 48
        } else {
            return .leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let teacher = getTeacherIfExist() {
            teacherLabel.text = "\(NSLocalizedString("Teacher", comment: "")) : \(teacher.name)"
            let shouldProcessInteracting = users.contains(where: { $0.status.isRaisingHand || $0.status.isSpeak })
            if isTeacher {
                stopInteractingButton.isHidden =  !shouldProcessInteracting
            } else {
                stopInteractingButton.isHidden = true
            }
            return teacherHeaderView
        } else {
            return nil
        }
    }
}
