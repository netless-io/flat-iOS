//
//  WhiteboardAppsCell.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/5.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class WhiteboardAppsCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        appIconView.contentMode = .center
        appIconView.clipsToBounds = true
        appIconView.layer.cornerRadius = 12
        appIconView.tintColor = .whiteText
        contentView.addSubview(appIconView)
        contentView.addSubview(appTitleLabel)
        appIconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        
        appTitleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var appIconView = UIImageView()
    lazy var appTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .color(type: .text)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
}
