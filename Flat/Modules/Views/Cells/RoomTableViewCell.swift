//
//  RoomTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Kingfisher

class RoomTableViewCell: UITableViewCell {
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var ownerAvatarView: UIImageView!
    @IBOutlet weak var roomTimeLabel: UILabel!
    @IBOutlet weak var roomTitleLabel: UILabel!
    @IBOutlet weak var recordIconView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = .color(type: .background)
        roomTitleLabel.textColor = .color(type: .text, .strong)
        roomTimeLabel.textColor = .color(type: .text)

        contentView.layer.insertSublayer(selectionShapeLayer, at: 0)
        contentView.addLine(direction: .bottom,
                            color: .borderColor,
                            inset: .init(top: 0, left: 64, bottom: 0, right: 16))
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
            v.selectionShapeLayer.fillColor = color.resolveDynamicColorPatchiOS13With(v.traitCollection).cgColor
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
        
        if room.roomStatus == .Started {
            roomTimeLabel.text = localizeStrings(room.roomStatus.rawValue) + " " + timeStr
            roomTimeLabel.textColor = .color(type: .success)
        } else {
            roomTimeLabel.text = dateStr + " " + timeStr
            roomTimeLabel.textColor = .color(type: .text)
        }
        
        calendarIcon.isHidden = (room.periodicUUID ?? "").isEmpty
        
        let scale = UIScreen.main.scale
        let avatarWidth: CGFloat = max(scale * 32, ownerAvatarView.bounds.width * scale)
        let avatarProcessor = ResizingImageProcessor(referenceSize: .init(width: avatarWidth, height: avatarWidth))
        ownerAvatarView.kf.setImage(with: URL(string: room.ownerAvatarURL), options: [.processor(avatarProcessor)])
        
        recordIconView.isHidden = !room.hasRecord
    }
    
    lazy var selectionShapeLayer = CAShapeLayer()
}
