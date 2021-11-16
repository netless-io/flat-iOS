//
//  ChatViewController1.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/16.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

class ChatViewController1: PopOverDismissDetectableViewController {
    let noticeCellIdentifier = "noticeCellIdentifier"
    let cellIdentifier = "cellIdentifier"
    let viewModel: ChatViewModel
    
    let userRtmId: String
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
    
    var messages: [DisplayMessage] = [] {
        didSet {
            tableView.reloadData()
            let last = tableView.numberOfRows(inSection: 0) - 1
            if last >= 0 {
                tableView.scrollToRow(at: IndexPath(row: last, section: 0), at: .middle, animated: true)
            }
        }
    }

    // MARK: - LifeCycle
    init(viewModel: ChatViewModel,
         userRtmId: String) {
        self.viewModel = viewModel
        self.userRtmId = userRtmId
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
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
        tableView.contentInset = .init(top: topView.bounds.height, left: 0, bottom: inputStackView.bounds.height, right: 0)
    }
    
    // MARK: - Private
    func bind() {
        let returnKey = inputTextField.rx.controlEvent(.editingDidEndOnExit)
        let send = Driver.of(returnKey.asDriver(),
                             sendButton.rx.tap.asDriver())
            .merge()
        
        let output = viewModel.tranform(input: .init(sendTap: send,
                                                     textInput: inputTextField.rx.text.orEmpty.asDriver()))
        
        output.sendMessageEnable
            .drive(sendButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        output.sendMessage
            .drive(with: self, onNext: { weakSelf, _ in
                weakSelf.inputTextField.text = nil
                weakSelf.inputTextField.sendActions(for: .valueChanged)
            })
            .disposed(by: rx.disposeBag)
        
        output.message.asDriver(onErrorJustReturn: [])
            .drive(with: self, onNext: { weakSelf, msgs in
                weakSelf.messages = msgs
            })
            .disposed(by: rx.disposeBag)
    }
    
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
    
    @objc func onClickBan() {
//        delegate?.chatViewControllerDidClickBanMessage(self)
    }
    
    // MARK: - Lazy
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "send_message")?.tintColor(.controlDisabled), for: .normal)
        button.setImage(UIImage(named: "send_message")?.tintColor(.controlNormal), for: .normal)
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

extension ChatViewController1: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        switch message {
        case .user(message: let message, name: let name):
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
            cell.update(nickName: name,
                        text: message.text,
                        style: message.userId == userRtmId ? .self : .other)
            print("chat", message.userId, userRtmId)
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
        case .user(message: let message, _):
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
