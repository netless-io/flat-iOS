//
//  ClassRoomSettingTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class ClassRoomSettingTableViewCell: UITableViewCell {
    var switchValueChangedHandler: ((Bool)->Void)?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        iconView.image = iconView.image?.tintColor(.nickname)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .classroomChildBG
        label.textColor = .nickname
        lineHeightConstraint.constant = 1 / UIScreen.main.scale
    }
    
    @IBAction func valueChanged(_ sender: UISwitch) {
        switchValueChangedHandler?(sender.isOn)
    }
    
    func setEnable(_ enable: Bool) {
        `switch`.isEnabled = enable
        label.textColor = enable ? .subText : UIColor.subText.withAlphaComponent(0.5)
    }
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var lineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
}
