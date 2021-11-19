//
//  RtcNoTeachCollectionViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/5.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RtcNoTeachCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let imageView = UIImageView(image: UIImage(named: "teach_not_showup"))
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
