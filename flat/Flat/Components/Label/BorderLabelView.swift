//
//  BorderLabel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/5.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class BorderLabelView: UIView {
    var edge: UIEdgeInsets? {
        didSet {
            label.snp.remakeConstraints { make in
                make.edges.equalTo(edge ?? .zero)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .commonBG
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .subText
        return label
    }()
}
