//
//  StrokeColorCollectionViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class StrokeColorCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        clipsToBounds = true
        layer.cornerRadius = 5
        layer.borderColor = UIColor.brandColor.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func update(color: UIColor, selected: Bool) {
        let img = UIImage.pickerItemImage(withColor: color, size: .init(width: 20, height: 20), radius: 10)
        colorView.image = img
        layer.borderWidth = selected ? 1.25 : 0
    }
    
    lazy var colorView = UIImageView()
}
