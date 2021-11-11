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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lineHeightConstraint.constant = 1 / UIScreen.main.scale
    }
    @IBAction func switchValueChanged(_ sender: Any) {
        if let i = sender as? UISwitch {
            switchValueChangedHandler?(i.isOn)
        }
    }
    
    @IBOutlet weak var lineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
}
