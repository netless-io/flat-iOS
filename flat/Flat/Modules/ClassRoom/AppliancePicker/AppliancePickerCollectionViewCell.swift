//
//  AppliancePickerCollectionViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class AppliancePickerCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        return view
    }()
}
