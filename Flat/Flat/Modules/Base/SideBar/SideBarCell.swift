//
//  SideBarCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/16.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class SideBarCell: UICollectionViewCell {
    var rawImage: UIImage? {
        didSet {
            syncSelected()
        }
    }
    
    func syncSelected() {
        iconImageView.image = rawImage?.tintColor(isSelected ? .white : .subText)
        itemTitleLabel.textColor = isSelected ? .white : .subText
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackBG
        let stack = UIStackView(arrangedSubviews: [iconImageView, itemTitleLabel])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 4
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(64)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            syncSelected()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - LAZY
    lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var itemTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        return label
    }()
}
