//
//  UIButton+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class FlatGeneralButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override var intrinsicContentSize: CGSize {
        let old = super.intrinsicContentSize
        if old.width <= 86 {
            return .init(width: 86, height: old.height)

        } else {
            return old
        }
    }
    
    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        setBackgroundImage(.imageWith(color: .brandColor), for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 14)
        contentEdgeInsets = .init(top: 6, left: 15, bottom: 6, right: 15)
    }
}
