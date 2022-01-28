//
//  RoomTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RoomTableViewCell: UITableViewCell {
    @IBOutlet weak var roomTimeLabel: UILabel!
    @IBOutlet weak var roomTitleLabel: UILabel!
    @IBOutlet weak var calendarLabel: UILabel!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mainTextView: UIView!
    @IBOutlet weak var borderView: UIView!
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setSelected(isSelected, animated: false)
        selectedBackgroundView = UIImageView(image: UIImage.imageWith(color: .cellSelectedBG))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIImageView(image: UIImage.imageWith(color: .cellSelectedBG))
        separatorLineHeightConstraint.constant = 1 / UIScreen.main.scale
        contentView.backgroundColor = .whiteBG
        borderView.backgroundColor = .borderColor
        calendarLabel.textColor = .text
        roomTitleLabel.textColor = .text
        roomTimeLabel.textColor = .subText
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if animated {
            contentView.layer.backgroundColor = selected ? UIColor.cellSelectedBG.cgColor : UIColor.whiteBG.cgColor
            mainTextView.layer.backgroundColor = selected ?  UIColor.cellSelectedBG.cgColor : UIColor.whiteBG.cgColor
        } else {
            contentView.backgroundColor = selected ?  .cellSelectedBG : .whiteBG
            mainTextView.backgroundColor = selected ?  .cellSelectedBG : .whiteBG
        }
    }
    
    @IBOutlet weak var separatorLineHeightConstraint: NSLayoutConstraint!
}
