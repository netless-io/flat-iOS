//
//  ClassTypeCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class ClassTypeCell: UIControl {
    var oldState: State?
    
    override var isSelected: Bool {
        didSet {
            if let oldState = oldState, oldState == state {
                return
            }
            syncState(state)
            oldState = state
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if let oldState = oldState, oldState == state {
                return
            }
            syncState(state)
            oldState = state
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        syncState(.normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    lazy var selectedImage = UIImage.filledCircleImage(radius: 16)
    
    func syncState(_ state: ClassTypeCell.State) {
        let circle = UIImage(named: "circle")!
        switch state {
        case .normal:
            layer.borderColor = UIColor.borderColor.cgColor
            layer.borderWidth = 1
            selectedIndicatorImageView.image = circle
        case .highlighted:
            layer.borderColor = UIColor.brandColor.cgColor
            layer.borderWidth = 1
            typeImageView.transform = .init(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.2) {
                self.typeImageView.transform = .identity
            }
        case .selected:
            layer.borderColor = UIColor.brandColor.cgColor
            layer.borderWidth = 2
            selectedIndicatorImageView.image = selectedImage
        default:
            return
        }
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
    
    // MARK: - Lazy
    lazy var typeDescriptionLabel: UILabel = {
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
        view.addSubview(selectedIndicatorImageView)
        selectedIndicatorImageView.snp.makeConstraints { make in
            make.right.bottom.top.equalToSuperview()
            make.width.equalTo(selectedIndicatorImageView.snp.height)
        }
        return view
    }()
    
    lazy var selectedIndicatorImageView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .borderColor
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()
    
    lazy var rightItemsStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [typeLabel, typeDescriptionLabel, selectedIndicatorImageVIewContainer])
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
