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
}

class ClassRoomUsersViewController: PopOverDismissDetectableViewController {
    let cellIdentifier = "cellIdentifier"

    weak var delegate: ClassRoomUsersViewControllerDelegate?
    var roomOwnerRtmUUID: String = "" {
        didSet {
            tableView.reloadData()
        }
    }
    
    var users: [RoomUser] = [] {
        didSet {
            tableView.reloadData()
        }
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
    
    func config(cell: RoomUserTableViewCell, user: RoomUser) {
        if user.rtmUUID == roomOwnerRtmUUID {
            cell.nameLabel.text = user.name + "(\(NSLocalizedString("Teach", comment: "")))"
        } else {
            cell.nameLabel.text = user.name
        }
        // TODO: maybe user status = error ??
        cell.avatarImageView.kf.setImage(with: user.avatarURL)
        cell.disconnectButton.isHidden = true
        cell.raiseHandButton.isHidden = true
        cell.cameraButton.isSelected = user.status?.camera ?? false
        cell.micButton.isSelected = user.status?.mic ?? false
        if let status = user.status {
            if status.isRaisingHand {
                cell.statusLabel.text = "(\(NSLocalizedString("Raised Hand", comment: "")))"
                cell.statusLabel.textColor = .controlSelected
                cell.raiseHandButton.isHidden = false
            } else if status.isSpeak {
                cell.statusLabel.text = "(\(NSLocalizedString("Mic Opening", comment: "")))"
                cell.statusLabel.textColor = .init(hexString: "#9FDF76")
                cell.disconnectButton.isHidden = false
            } else {
                cell.statusLabel.text = nil
            }
        } else {
            cell.statusLabel.text = nil
        }
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
        view.rowHeight = 54
        return view
    }()
}

extension ClassRoomUsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RoomUserTableViewCell
        config(cell: cell, user: users[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
