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
    
    var bgSize: CGSize = .zero
    
    override var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            backgroundColor = isEnabled ? .brandColor : .controlDisabled
        }
    }
    
    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        backgroundColor = .brandColor
        setTitleColor(.whiteText, for: .normal)
        setTitleColor(.disableText, for: .disabled)
        setTitleColor(UIColor.whiteText.withAlphaComponent(0.7), for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 16)
    }
}
