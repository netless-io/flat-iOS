//
//  RaiseHandTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2022/12/29.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class RaiseHandTableViewCell: UITableViewCell {
    var clickAcceptHandler: (()->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        selectionStyle = .none
        contentView.backgroundColor = .classroomChildBG
        contentView.addSubview(nameLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(raiseHandButton)
        
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(56)
            make.centerY.equalToSuperview()
            make.right.equalTo(raiseHandButton.snp.left)
        }
        
        raiseHandButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(66)
        }
    }
    
    @objc func onClickRaiseHand() {
        clickAcceptHandler?()
    }
    
    lazy var raiseHandButton: UIButton = {
        let raiseHandButton = UIButton(type: .custom)
        raiseHandButton.setTitle(localizeStrings("Agree"), for: .normal)
        raiseHandButton.setTitleColor(.color(type: .primary), for: .normal)
        raiseHandButton.titleLabel?.font = .systemFont(ofSize: 14)
        raiseHandButton.addTarget(self, action: #selector(onClickRaiseHand), for: .touchUpInside)
        return raiseHandButton
    }()
    
    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.textColor = .color(type: .text)
        return nameLabel
    }()
    
    lazy var avatarImageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        return view
    }()
}
