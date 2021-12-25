//
//  BorderPopoverBackgrounView.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/26.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class BorderPopoverBackgrounView: UIPopoverBackgroundView {
    override class func contentViewInsets() -> UIEdgeInsets { .init(top: 4, left: 4, bottom: 4, right: 4) }
    
    override class func arrowHeight() -> CGFloat { 0 }
    
    override class func arrowBase() -> CGFloat { 0 }
    
    private var _arrowDirection: UIPopoverArrowDirection = .right
    override var arrowDirection: UIPopoverArrowDirection {
        get {
            return _arrowDirection
        }
        set {
            _arrowDirection = newValue
        }
    }

    private var _arrowOffset: CGFloat = 0
    override var arrowOffset: CGFloat {
        get {
            _arrowOffset
        }
        set {
            _arrowOffset = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .white
        layer.cornerRadius = 4
        layer.borderColor = UIColor.popoverBorder.cgColor
        layer.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
