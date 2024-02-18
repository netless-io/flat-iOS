//
//  RoomTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Kingfisher
import UIKit

class RoomTableViewCell: UITableViewCell {
    @IBOutlet var rightAreaContainer: UIView!
    @IBOutlet var calendarIcon: UIImageView!
    @IBOutlet var ownerAvatarView: UIImageView!
    @IBOutlet var roomTimeLabel: UILabel!
    @IBOutlet var roomTitleLabel: UILabel!
    @IBOutlet var recordIconView: UIImageView!
    
    var joinButtonCallback: ((UIButton?)->Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = .color(type: .background)
        roomTitleLabel.textColor = .color(type: .text, .strong)
        roomTimeLabel.textColor = .color(type: .text)
        ownerAvatarView.backgroundColor = .color(type: .background, .strong)

        contentView.layer.insertSublayer(selectionShapeLayer, at: 0)
        contentView.addLine(direction: .bottom,
                            color: .borderColor,
                            inset: .init(top: 0, left: 64, bottom: 0, right: 16))
    }

    @objc func onClickJoin(_ btn: UIButton) {
        joinButtonCallback?(btn)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: 1, left: 8, bottom: 2, right: 8)), cornerRadius: 6)
        selectionShapeLayer.path = path.cgPath
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setTraitRelatedBlock { v in
            let color = selected ? UIColor.color(type: .primary, .weak) : UIColor.clear
            v.selectionShapeLayer.fillColor = color.resolvedColor(with: v.traitCollection).cgColor
        }
    }

    func render(info room: RoomBasicInfo) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        if let code = LocaleManager.languageCode {
            let locale = Locale(identifier: code)
            formatter.locale = locale
        }
        let dateStr: String

        if Calendar.current.isDateInToday(room.beginTime) {
            dateStr = localizeStrings("Today")
        } else if Calendar.current.isDateInTomorrow(room.beginTime) {
            dateStr = localizeStrings("Tomorrow")
        } else {
            dateStr = formatter.string(from: room.beginTime)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateFormat = "HH:mm"
        let timeStr = timeFormatter.string(from: room.beginTime) + "~" + timeFormatter.string(from: room.endTime)

        roomTitleLabel.text = room.title

        roomTimeLabel.text = dateStr + " " + timeStr
        roomTimeLabel.textColor = .color(type: .text)

        calendarIcon.isHidden = (room.periodicUUID ?? "").isEmpty

        let scale = UIScreen.main.scale
        let avatarWidth: CGFloat = max(scale * 32, ownerAvatarView.bounds.width * scale)
        let avatarProcessor = ResizingImageProcessor(referenceSize: .init(width: avatarWidth, height: avatarWidth))
        ownerAvatarView.kf.setImage(with: URL(string: room.ownerAvatarURL), options: [.processor(avatarProcessor), .transition(.fade(0.3))])

        recordIconView.isHidden = !room.hasRecord

        rightStatusLabel.removeFromSuperview()
        joinButton.removeFromSuperview()

        let isTooEarlyInterval = TimeInterval(60 * 60) // 1 hour.
        let joinEarlyInterval = Env().joinEarly
        let interval = room.beginTime.timeIntervalSince(Date())
        if interval > isTooEarlyInterval { // Show status only.
            rightAreaContainer.addSubview(rightStatusLabel)
            rightStatusLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            rightStatusLabel.text = localizeStrings(room.roomStatus.rawValue)
            if room.roomStatus != .Started {
                rightStatusLabel.textColor = .color(type: .warning)
            } else {
                rightStatusLabel.textColor = .color(type: .success)
            }
        } else if interval > joinEarlyInterval { // Show count down.
            rightAreaContainer.addSubview(rightStatusLabel)
            rightStatusLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            let minutes = Int(interval / 60)
            rightStatusLabel.text = String(format: NSLocalizedString("RoomListCountString %d", comment: "Room count down label"), minutes)
            rightStatusLabel.textColor = .color(type: .success)
        } else { // Show button.
            rightAreaContainer.addSubview(joinButton)
            joinButton.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.size.equalTo(CGSize(width: 80, height: 44))
            }
            if room.isOwner, room.roomStatus == .Idle {
                joinButton.setTitle(localizeStrings("Start"), for: .normal)
            } else {
                joinButton.setTitle(localizeStrings("Enter"), for: .normal)
            }
        }
    }

    lazy var selectionShapeLayer = CAShapeLayer()
    lazy var rightStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()

    lazy var joinButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton(type: .system)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.color(type: .primary, .strong).cgColor
        btn.addTarget(self, action: #selector(onClickJoin))
        return btn
    }()
}
