//
//  ChatNoticeTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/5.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class ChatNoticeTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        selectionStyle = .none
        contentView.addSubview(labelView)
        labelView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        labelView.edge = .init(top: 6, left: 12, bottom: 6, right: 12)
    }
    
    lazy var labelView = BorderLabel()
}
