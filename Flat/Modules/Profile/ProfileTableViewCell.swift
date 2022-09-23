//
//  ProfileTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/22.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .color(type: .background)
        selectionStyle = .none
        contentView.addSubview(profileTitleLabel)
        contentView.addSubview(rightStackView)
        profileTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        rightStackView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        addLine(direction: .bottom, color: .borderColor, inset: .init(top: 0, left: 16, bottom: 0, right: 16))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var rightStackView = UIStackView(arrangedSubviews: [profileDetailTextLabel, avatarImageView, rightArrowView])
    
    lazy var rightArrowView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "right"))
        view.tintColor = .color(type: .text)
        view.contentMode = .center
        return view
    }()
    
    lazy var avatarImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .grey0
        view.clipsToBounds = true
        return view
    }()
    
    lazy var profileTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .color(type: .text)
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    lazy var profileDetailTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = .color(type: .text)
        label.font = .systemFont(ofSize: 16)
        return label
    }()
}
