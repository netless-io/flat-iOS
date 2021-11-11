//
//  JoinRoomViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class JoinRoomViewController: UIViewController {
    // MARK: - LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fillTextfieldWithPasterBoard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Action
    @objc func onJoin(_ sender: UIButton) {
        guard let uuid = subjectTextField.text, !uuid.isEmpty else {
            return
        }
        RoomPlayInfo.fetchByJoinWith(uuid: uuid) { joinResult in
            switch joinResult {
            case .success(let roomPlayInfo):
                RoomInfo.fetchInfoBy(uuid: roomPlayInfo.roomUUID) { infoResult in
                    switch infoResult {
                    case .success(let roomInfo):
                        let vc = ClassRoomViewController(roomPlayInfo: roomPlayInfo, roomInfo: roomInfo, cameraOn: false, micOn: false)
                        if let split = self.splitViewController {
                            split.present(vc, animated: true, completion: nil)
                        } else {
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    case .failure(let roomInfoError):
                        self.showAlertWith(message: roomInfoError.localizedDescription)
                    }
                }
            case .failure(let joinError):
                self.showAlertWith(message: joinError.localizedDescription)
            }
        }
    }
    
    // MARK: - Private
    func fillTextfieldWithPasterBoard() {
        guard (subjectTextField.text ?? "").isEmpty else { return }
        if let str = UIPasteboard.general.string, !str.isEmpty {
            if let r = try? str.matchExpressionPattern("(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"),
                let url = URL(string: r) {
                let id = url.lastPathComponent
                subjectTextField.text = id
            } else {
                subjectTextField.text = str
            }
        }
    }
    
    func setupViews() {
        navigationItem.title = NSLocalizedString("Join Room", comment: "")
        view.backgroundColor = .white
        let topLabel = UILabel()
        topLabel.font = .systemFont(ofSize: 14)
        topLabel.textColor = .subText
        topLabel.text = NSLocalizedString("Room Number", comment: "")
        view.addSubview(topLabel)
        view.addSubview(subjectTextField)
        view.addSubview(joinButton)
        
        let margin: CGFloat = 16
        topLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(margin)
        }
        subjectTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(46)
            make.height.equalTo(48)
        }
        
        joinButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(margin)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(110)
            make.height.equalTo(32)
        }
    }
    
    // MARK: - Lazy
    lazy var subjectTextField: UITextField = {
        let tf = UITextField()
        tf.layer.borderColor = UIColor.borderColor.cgColor
        tf.layer.borderWidth = 1 / UIScreen.main.scale
        tf.layer.cornerRadius = 4
        tf.clipsToBounds = true
        tf.textColor = .text
        tf.font = .systemFont(ofSize: 14)
        tf.placeholder = NSLocalizedString("Room Number Input PlaceHolder", comment: "")
        tf.leftView = .init(frame: .init(origin: .zero, size: .init(width: 10, height: 20)))
        tf.leftViewMode = .always
        tf.keyboardType = .numberPad
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    lazy var joinButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 4
        btn.backgroundColor = .brandColor
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(NSLocalizedString("Join", comment: ""), for: .normal)
        btn.addTarget(self, action: #selector(onJoin(_:)), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 0, left: 29, bottom: 0, right: 29)
        return btn
    }()
}
