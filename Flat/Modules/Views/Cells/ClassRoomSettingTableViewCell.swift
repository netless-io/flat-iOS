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
        iconView.image = iconView.image?.tintColor(.color(type: .text))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .classroomChildBG
        contentView.backgroundColor = .classroomChildBG
        label.textColor = .color(type: .text)
        lineHeightConstraint.constant = 1
        borderView.backgroundColor = .borderColor
    }
    
    @IBAction func valueChanged(_ sender: UISwitch) {
        switchValueChangedHandler?(sender.isOn)
    }
    
    func setEnable(_ enable: Bool) {
        `switch`.isEnabled = enable
        label.textColor = enable ? .color(type: .text) : UIColor.color(type: .text).withAlphaComponent(0.5)
        iconView.alpha = enable ? 1 : 0.5
    }
    
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var lineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
}
