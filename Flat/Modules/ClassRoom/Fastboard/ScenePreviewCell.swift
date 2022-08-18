//
//  ScenePreviewCell.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class ScenePreviewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
            make.height.equalTo(previewImageView.snp.width).multipliedBy(9.0/16.0)
        }
        previewImageView.layer.borderColor = UIColor.lightGray.cgColor
        previewImageView.layer.borderWidth = 1 / UIScreen.main.scale
        previewImageView.layer.cornerRadius = 4
        previewImageView.contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var previewImageView = UIImageView()
}
