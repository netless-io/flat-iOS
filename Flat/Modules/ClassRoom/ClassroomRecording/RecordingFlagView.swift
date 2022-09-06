//
//  RecordingFlagView.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class RecordingFlagView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(durationLabel)
        addSubview(endRecordingButton)
        backgroundColor = .whiteBG
        
        clipsToBounds = true
        layer.cornerRadius = 22
        
        durationLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let img = UIImage.imageWith(color: .systemRed, size: .init(width: 15, height: 15))
        endRecordingButton.setImage(img, for: .normal)
        endRecordingButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 100, height: 44)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .color(type: .text)
        label.text = "00 : 00"
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()
    
    lazy var endRecordingButton: UIButton = {
        let btn = UIButton(type: .custom)
        return btn
    }()
}
