//
//  RaiseHandButton.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RaiseHandButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(UIImage(named: "raisehand_selected")?.withRenderingMode(.alwaysOriginal), for: .normal)
        setImage(UIImage(named: "raisehand")?.withRenderingMode(.alwaysOriginal), for: .highlighted)
        setImage(UIImage(named: "raisehand")?.withRenderingMode(.alwaysOriginal), for: .selected)
        
        addSubview(borderView)
        borderView.clipsToBounds = true
        borderView.layer.borderWidth = 6
        borderView.isUserInteractionEnabled = false
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(-8)
        }
        
        isSelected = isSelected
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderView.layer.cornerRadius = (bounds.width + 16) / 2
    }
    
    override var isSelected: Bool {
        didSet {
            borderView.layer.borderColor = isSelected ? UIColor.borderColor.withAlphaComponent(0.15).cgColor : UIColor.color(type: .primary).withAlphaComponent(0.15).cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    lazy var borderView = UIView()
}
