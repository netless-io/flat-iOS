//
//  SettingTableViewCell.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class SettingTableViewCell: UITableViewCell {
    @IBOutlet weak var settingDetailLabel: UILabel!
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryType = .disclosureIndicator
        settingTitleLabel.textColor = .text
        settingDetailLabel.textColor = .subText
        backgroundColor = .whiteBG
        contentView.backgroundColor = .whiteBG
    }
}
