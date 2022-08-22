//
//  ChatTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class ChatTableViewCell: UITableViewCell {
    static let nickNameHeight: CGFloat = 22
    static let textFont = UIFont.systemFont(ofSize: 14)
    static let textEdge: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    static let textMargin: CGFloat = 8
    static let bottomMargin: CGFloat = 8
    
    enum Style {
        case other
        case `self`
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        selectionStyle = .none
        contentView.backgroundColor = .whiteBG
        contentView.addSubview(nickNameLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(chatContentLabel)
        nickNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(ChatTableViewCell.textMargin)
        }
        chatContentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ChatTableViewCell.textEdge)
            make.width.greaterThanOrEqualTo(10)
        }
    }
    
    func update(nickName: String, text: String, style: Style) {
        nickNameLabel.text = nickName
        chatContentLabel.text = text
        switch style {
        case .other:
            nickNameLabel.isHidden = false
            bubbleView.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(ChatTableViewCell.textMargin)
                make.right.lessThanOrEqualToSuperview().inset(ChatTableViewCell.textMargin)
                make.top.equalToSuperview().inset(ChatTableViewCell.nickNameHeight)
                make.bottom.equalToSuperview().inset(ChatTableViewCell.bottomMargin)
            }
            chatContentLabel.textColor = .text
            bubbleView.backgroundColor = .commonBG
        case .self:
            nickNameLabel.isHidden = true
            bubbleView.snp.remakeConstraints { make in
                make.right.equalToSuperview().inset(ChatTableViewCell.textMargin)
                make.left.greaterThanOrEqualToSuperview().inset(ChatTableViewCell.textMargin)
                make.top.equalToSuperview().inset(0)
                make.bottom.equalToSuperview().inset(ChatTableViewCell.bottomMargin)
            }
            chatContentLabel.textColor = .white
            bubbleView.backgroundColor = .brandColor
        }
    }
    
    lazy var nickNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .subText
        return label
    }()

    lazy var bubbleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()
    
    lazy var chatContentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = ChatTableViewCell.textFont
        label.numberOfLines = 0
        return label
    }()
}
