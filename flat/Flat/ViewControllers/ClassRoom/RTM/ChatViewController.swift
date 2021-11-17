//
//  ChatViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//  Implement Chat UI


import UIKit

protocol ChatViewControllerDelegate: AnyObject{
    func chatViewControllerDidSendMessage(_ controller: ChatViewController, message: String)
    
    func chatViewControllerNeedNickNameForUserId(_ controller: ChatViewController, userId: String) -> String?
    
    func chatViewControllerDidClickBanMessage(_ controller: ChatViewController)
}

class ChatViewController: PopOverDismissDetectableViewController {
    let noticeCellIdentifier = "noticeCellIdentifier"
    let cellIdentifier = "cellIdentifier"
    
    weak var delegate: ChatViewControllerDelegate?
    var userRtmId: String = ""
    /// If message is baning now
    var isInMessageBan = false {
        didSet {
            banTextButton.isSelected = isInMessageBan
        }
    }
    /// Is message been baned
    var isMessageBaned = false {
        didSet {
            updateDidMessageBan(isMessageBaned)
        }
    }
    
    var messages: [Message] = [] {
        didSet {
            tableView.reloadData()
            let last = tableView.numberOfRows(inSection: 0) - 1
            if last >= 0 {
                tableView.scrollToRow(at: IndexPath(row: last, section: 0), at: .middle, animated: true)
            }
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
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
        tableView.contentInset = .init(top: topView.bounds.height, left: 0, bottom: inputStackView.bounds.height, right: 0)
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        let inputBg = UIView()
        inputBg.backgroundColor = .white
        view.addSubview(inputBg)
        view.addSubview(inputStackView)
        view.addSubview(topView)

        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(34)
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addLayoutGuide(leftMarginGuide)
        leftMarginGuide.snp.makeConstraints { make in
            make.bottom.height.equalTo(inputStackView)
            make.left.equalToSuperview()
            make.width.equalTo(0)
        }
        inputStackView.snp.makeConstraints { make in
            make.left.equalTo(leftMarginGuide.snp.right)
            make.right.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(48)
        }
        
        inputBg.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(inputStackView)
        }
    }
    
    // Call it after view did load
    func updateBanTextButtonEnable(_ enable: Bool) {
        banTextButton.isHidden = !enable
        leftMarginGuide.snp.updateConstraints { make in
            make.width.equalTo(enable ? 0 : 8)
        }
    }
    
    fileprivate func updateDidMessageBan(_ ban: Bool) {
        sendButton.isEnabled = !ban
        inputTextField.isEnabled = !ban
        if ban {
            inputTextField.text = nil
        }
        inputTextField.placeholder = ban ? NSLocalizedString("All banned", comment: ""): NSLocalizedString("Say Something...", comment: "")
    }
    
    // MARK: - Action
    @objc func onClickSendMessage() {
        guard let text = inputTextField.text, !text.isEmpty else { return }
        delegate?.chatViewControllerDidSendMessage(self, message: text)
        messages.append(.user(.init(userId: userRtmId, text: text)))
        inputTextField.text = nil
        let rowCount = tableView(tableView, numberOfRowsInSection: 0)
        tableView.scrollToRow(at: .init(row: rowCount - 1, section: 0), at: .bottom, animated: true)
    }
    
    @objc func onClickBan() {
        delegate?.chatViewControllerDidClickBanMessage(self)
    }
    
    // MARK: - Lazy
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "send_message")?.tintColor(.controlDisabled), for: .normal)
        button.setImage(UIImage(named: "send_message")?.tintColor(.controlNormal), for: .normal)
        button.addTarget(self, action: #selector(onClickSendMessage), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        return button
    }()
    
    lazy var leftMarginGuide = UILayoutGuide()
    
    lazy var inputStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [banTextButton, textFieldContainer, sendButton])
        view.axis = .horizontal
        view.distribution = .fill
        return view
    }()
    
    lazy var textFieldContainer: UIView = {
        let container = UIView()
        container.addSubview(inputTextField)
        inputTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 8, left: 0, bottom: 8, right: 0))
        }
        return container
    }()
    
    lazy var banTextButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "message_ban")?.tintColor(.controlNormal), for: .normal)
        btn.setImage(UIImage(named: "message_ban")?.tintColor(.controlSelected), for: .selected)
        btn.addTarget(self, action: #selector(onClickBan), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        return btn
    }()
    
    lazy var inputTextField: UITextField = {
        let inputTextField = UITextField.init(frame: .zero)
        inputTextField.backgroundColor = .white
        inputTextField.clipsToBounds = true
        inputTextField.layer.borderWidth = 1 / UIScreen.main.scale
        inputTextField.layer.cornerRadius = 4
        inputTextField.layer.borderColor = UIColor.borderColor.cgColor
        inputTextField.font = .systemFont(ofSize: 14)
        inputTextField.placeholder = NSLocalizedString("Say Something...", comment: "")
        inputTextField.returnKeyType = .send
        inputTextField.leftView = UIView(frame: .init(x: 0, y: 0, width: 8, height: 8))
        inputTextField.leftViewMode = .always
        inputTextField.delegate = self
        return inputTextField
    }()
    
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        let topLabel = UILabel(frame: .zero)
        topLabel.text = NSLocalizedString("Chat", comment: "")
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
        view.register(ChatTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.register(ChatNoticeTableViewCell.self, forCellReuseIdentifier: noticeCellIdentifier)
        view.delegate = self
        view.dataSource = self
        return view
    }()
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        switch message {
        case .user(let message):
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
            let nickName = delegate?.chatViewControllerNeedNickNameForUserId(self, userId: message.userId)
            cell.update(nickName: nickName ?? "", text: message.text, style: message.userId == userRtmId ? .self : .other)
            return cell
        case .notice(let notice):
            let cell = tableView.dequeueReusableCell(withIdentifier: noticeCellIdentifier, for: indexPath) as! ChatNoticeTableViewCell
            cell.labelView.label.text = notice
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        switch message {
        case .user(let message):
            let isSelf = message.userId == userRtmId
            let width = view.bounds.width - (2 * ChatTableViewCell.textMargin) - ChatTableViewCell.textEdge.left - ChatTableViewCell.textEdge.right
            let textSize = message.text.boundingRect(with: .init(width: width,
                                                  height: .greatestFiniteMagnitude),
                                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                                      attributes: [.font: ChatTableViewCell.textFont],
                                      context: nil).size
            var height: CGFloat = textSize.height + ChatTableViewCell.textEdge.top + ChatTableViewCell.textEdge.bottom + ChatTableViewCell.bottomMargin
            if !isSelf {
                height += ChatTableViewCell.nickNameHeight
            }
            return height
        case .notice:
            return 26.5 + ChatTableViewCell.bottomMargin
        }
    }
    
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onClickSendMessage()
        return true
    }
}
