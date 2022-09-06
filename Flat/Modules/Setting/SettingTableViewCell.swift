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
    @IBOutlet weak var popOverAnchorView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var `switch`: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        settingTitleLabel.textColor = .color(type: .text)
        settingDetailLabel.textColor = .color(type: .text)
        backgroundColor = .whiteBG
        contentView.backgroundColor = .whiteBG
    }
}
