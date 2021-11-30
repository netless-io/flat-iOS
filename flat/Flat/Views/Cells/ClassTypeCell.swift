//
//  ClassTypeCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class ClassTypeCell: UIControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        syncSelected()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func syncSelected() {
        layer.borderColor = isSelected ? UIColor.brandColor.cgColor : UIColor.borderColor.cgColor
        layer.borderWidth = isSelected ? 2 : 1
        
        let circle = UIImage(named: "circle")!
        let selectedImg = UIImage.filledCircleImage(radius: circle.size.width / 2)
        selectedIndicatorImageVIew.image = isSelected ? selectedImg : UIImage(named: "circle")
    }
    
    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        addSubview(typeImageView)
        addSubview(rightItemsStackView)
        rightItemsStackView.snp.makeConstraints { make in
            make.top.bottom.equalTo(typeImageView)
            make.left.equalTo(typeImageView.snp.right).offset(6)
            make.right.equalToSuperview().inset(6)
        }
        typeImageView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(12)
            make.width.equalTo(typeImageView.snp.height)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            syncSelected()
        }
    }
    
    // MARK: - Lazy
    lazy var typeDescriptionLaebl: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .subText
        label.numberOfLines = 2
        return label
    }()
    
    lazy var typeLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .text
        return label
    }()
    
    lazy var selectedIndicatorImageVIewContainer: UIView = {
        let view = UIView()
        view.addSubview(selectedIndicatorImageVIew)
        selectedIndicatorImageVIew.snp.makeConstraints { make in
            make.right.bottom.top.equalToSuperview()
            make.width.equalTo(selectedIndicatorImageVIew.snp.height)
        }
        return view
    }()
    
    lazy var selectedIndicatorImageVIew: UIImageView = {
        let view = UIImageView()
        view.tintColor = .borderColor
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()
    
    lazy var rightItemsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [typeLabel, typeDescriptionLaebl, selectedIndicatorImageVIewContainer])
        view.isUserInteractionEnabled = false
        view.distribution = .fill
        view.axis = .vertical
        typeLabel.snp.makeConstraints { $0.height.equalTo(24) }
        selectedIndicatorImageVIewContainer.snp.makeConstraints { $0.height.equalTo(16) }
        return view
    }()
    
    lazy var typeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
}
