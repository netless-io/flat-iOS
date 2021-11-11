//
//  IndicateMoreButton.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class IndicateMoreButton: UIButton {
    var indicatorInset: UIEdgeInsets = .zero {
        didSet {
            indicatorView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(indicatorInset.top)
                make.right.equalToSuperview().inset(indicatorInset.right)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
        }
        syncIndicator()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var isSelected: Bool {
        didSet {
            syncIndicator()
        }
    }
    
    func syncIndicator() {
        indicatorView.tintColor = isSelected ? tintColor : .subText
    }
    
    lazy var indicatorView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "triangle_rt"))
        return view
    }()
}
