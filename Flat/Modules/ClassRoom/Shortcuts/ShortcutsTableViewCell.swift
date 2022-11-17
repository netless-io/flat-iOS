//
//  ShortcutsTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class ShortcutsTableViewCell: UITableViewCell {
    var switchHandler: ((Bool)->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: [shortcutsTitleLabel, shortcutsDetailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)
        contentView.backgroundColor = .classroomChildBG
        stack.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(88)
        }
        contentView.addSubview(shortcutsSwitch)
        shortcutsSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
        shortcutsSwitch.addTarget(self, action: #selector(onSwitchUpdate), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onSwitchUpdate(_ sender: UISwitch) {
        switchHandler?(sender.isOn)
    }
    
    lazy var shortcutsSwitch = UISwitch()
    
    lazy var shortcutsTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        return label
    }()
    
    lazy var shortcutsDetailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text, .weak)
        label.numberOfLines = 0
        return label
    }()
}
