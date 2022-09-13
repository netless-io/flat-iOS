//
//  UIView+seperatorLine.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

extension UIView {
    enum LineDirection {
        case top
        case bottom
        case left
        case right
    }
    
    @discardableResult
    func addLine(direction: LineDirection, color: UIColor, width: CGFloat = 1, inset: UIEdgeInsets = .zero) -> UIView {
        let line = UIView()
        addSubview(line)
        line.backgroundColor = color
        switch direction {
        case .top:
            line.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview().inset(inset)
                make.height.equalTo(width)
            }
        case .bottom:
            line.snp.makeConstraints { make in
                make.left.bottom.right.equalToSuperview().inset(inset)
                make.height.equalTo(width)
            }
        case .left:
            line.snp.makeConstraints { make in
                make.left.top.bottom.equalToSuperview().inset(inset)
                make.width.equalTo(width)
            }
        case .right:
            line.snp.makeConstraints { make in
                make.right.top.bottom.equalToSuperview().inset(inset)
                make.width.equalTo(width)
            }
        }
        return line
    }
}
