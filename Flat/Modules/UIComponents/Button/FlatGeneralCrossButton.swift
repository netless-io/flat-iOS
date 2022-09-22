//
//  FlatGeneralCrossButton.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/14.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

extension UIControl.State: Hashable {}

class FlatGeneralCrossButton: SpringButton {
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
    
    var bgSize: CGSize = .zero
    
    var backgroundColorDic: [UIControl.State: UIColor] = [
        .normal: .color(type: .primary),
        .disabled: .color(light: .grey2, dark: .grey8),
        .highlighted: .color(light: .blue5, dark: .blue6)
    ]
    
    override var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            backgroundColor = backgroundColorDic[isEnabled ? .normal : .disabled]
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            backgroundColor = backgroundColorDic[isHighlighted ? .highlighted : .normal]
        }
    }
    
    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        backgroundColor = .color(type: .primary)
        
        setTitleColor(.grey0, for: .normal)
        setTitleColor(.grey0, for: .highlighted)
        setTitleColor(.grey5, for: .disabled)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
}
