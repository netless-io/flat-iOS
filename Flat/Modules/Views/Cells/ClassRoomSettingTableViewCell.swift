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
        backgroundColor = .classroomChildBG
        contentView.backgroundColor = .classroomChildBG
        label.textColor = .color(type: .text)
        lineHeightConstraint.constant = commonBorderWidth
        borderView.backgroundColor = .borderColor
        
        iconView.setTraitRelatedBlock { v in
            v.image = v.image?.tintColor(.color(type: .text).resolveDynamicColorPatchiOS13With(v.traitCollection))
        }
        
        rightArrowImageView.setTraitRelatedBlock { v in
            v.image = v.image?.tintColor(.color(type: .text).resolveDynamicColorPatchiOS13With(v.traitCollection))
        }
        
        contentView.addSubview(rightArrowImageView)
        rightArrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
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
    
    lazy var rightArrowImageView = UIImageView(image: UIImage(named: "right")?.tintColor(.color(type: .text)))
}
