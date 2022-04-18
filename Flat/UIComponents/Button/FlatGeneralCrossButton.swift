//
//  FlatGeneralCrossButton.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/14.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class FlatGeneralCrossButton: UIButton {
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
        backgroundColor = .brandColor
        layer.cornerRadius = 4
        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
}
