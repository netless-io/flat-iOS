//
//  ChatTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

class ChatTableViewCell: UITableViewCell {
    static let nickNameHeight: CGFloat = 22
    static let textFont = UIFont.systemFont(ofSize: 14)
    static let textEdge: UIEdgeInsets = .init(top: 8, left: 12, bottom: 8, right: 12)
    static let textMargin: CGFloat = 52
    static let textTopMargin: CGFloat = 34
    static let topMargin: CGFloat = 12
    static let textAttribute: [NSAttributedString.Key: Any] = [
        .font: ChatTableViewCell.textFont,
        .paragraphStyle: {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = 6
            return paraStyle
        }(),
    ]

    enum Style {
        case other
        case `self`

        var backgroundColor: UIColor {
            switch self {
            case .other: return .color(light: .blue0, dark: .grey9)
            case .`self`: return .color(type: .primary)
            }
        }

        var textColor: UIColor {
            switch self {
            case .other: return .color(light: .blue8, dark: .blue0)
            case .`self`: return .init(hexString: "#F4F8FF")
            }
        }
    }

    var chatStyle: Style = .other

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func setupViews() {
        selectionStyle = .none
        backgroundColor = .classroomChildBG
        contentView.backgroundColor = .classroomChildBG
        contentView.addSubview(bubbleView)
        contentView.addSubview(avatarView)
        contentView.addSubview(infoStackView)
        bubbleView.addSubview(chatContentLabel)
        avatarView.layer.cornerRadius = 16
        chatContentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ChatTableViewCell.textEdge)
            make.width.greaterThanOrEqualTo(10)
        }
        contentView.addSubview(triangleContainer)
        triangleContainer.layer.addSublayer(triangleLayer)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        triangleLayer.fillColor = chatStyle.backgroundColor.cgColor
    }

    func update(nickName: String, text: String, time: String, avatar: URL?, isTeach: Bool, style: Style) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        nickNameLabel.text = nickName
        timeLabel.text = time
        avatarView.kf.setImage(with: avatar)
        chatStyle = style
        bubbleView.backgroundColor = style.backgroundColor
        triangleLayer.fillColor = style.backgroundColor.cgColor
        teacherIcon.isHidden = !isTeach

        var attr = ChatTableViewCell.textAttribute
        attr[.foregroundColor] = style.textColor
        chatContentLabel.attributedText = NSAttributedString(string: text, attributes: attr)
        switch style {
        case .other:
            avatarView.snp.remakeConstraints { make in
                make.left.top.equalToSuperview().inset(ChatTableViewCell.topMargin)
                make.width.height.equalTo(32)
            }
            infoStackView.arrangedSubviews.forEach { infoStackView.removeArrangedSubview($0) }
            infoStackView.addArrangedSubview(teacherIcon)
            infoStackView.addArrangedSubview(nickNameLabel)
            infoStackView.addArrangedSubview(timeLabel)
            infoStackView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(ChatTableViewCell.topMargin)
                make.left.equalToSuperview().inset(52)
            }
            bubbleView.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(ChatTableViewCell.textMargin)
                make.right.lessThanOrEqualToSuperview().inset(ChatTableViewCell.textMargin)
                make.top.equalToSuperview().inset(ChatTableViewCell.textTopMargin)
                make.bottom.equalToSuperview()
            }
            triangleContainer.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView).offset(12)
                make.right.equalTo(bubbleView.snp.left)
                make.width.height.equalTo(8)
            }
            triangleLayer.setAffineTransform(.init(scaleX: -1, y: 1).concatenating(.init(translationX: 8, y: 0)))
        case .self:
            avatarView.snp.remakeConstraints { make in
                make.right.top.equalToSuperview().inset(ChatTableViewCell.topMargin)
                make.width.height.equalTo(32)
            }
            infoStackView.arrangedSubviews.forEach { infoStackView.removeArrangedSubview($0) }
            infoStackView.addArrangedSubview(timeLabel)
            infoStackView.addArrangedSubview(nickNameLabel)
            infoStackView.addArrangedSubview(teacherIcon)
            infoStackView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(ChatTableViewCell.topMargin)
                make.right.equalToSuperview().inset(52)
            }
            bubbleView.snp.remakeConstraints { make in
                make.right.equalToSuperview().inset(ChatTableViewCell.textMargin)
                make.left.greaterThanOrEqualToSuperview().inset(ChatTableViewCell.textMargin)
                make.top.equalToSuperview().inset(ChatTableViewCell.textTopMargin)
                make.bottom.equalToSuperview()
            }
            triangleContainer.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView).offset(12)
                make.left.equalTo(bubbleView.snp.right)
                make.width.height.equalTo(8)
            }
            triangleLayer.setAffineTransform(.identity)
        }
        CATransaction.commit()
    }

    lazy var nickNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .init(hexString: "#B7BBC1")
        return label
    }()

    lazy var bubbleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        return view
    }()

    lazy var chatContentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()

    lazy var teacherIcon = UIImageView(image: UIImage(named: "teach_icon"))

    lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nickNameLabel, timeLabel, teacherIcon])
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()

    lazy var triangleContainer = UIView(frame: .init(origin: .zero, size: .init(width: 8, height: 8)))

    lazy var triangleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: .init(x: 8, y: 0))
        path.addLine(to: .init(x: 0, y: 8))
        path.closeSubpath()
        layer.path = path
        return layer
    }()
}
