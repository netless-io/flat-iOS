//
//  UIButton+Spacing.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIButton {
    public func horizontalCenterTitleAndImageWith(_ spacing: CGFloat) {
        setDidLayoutHandle { [weak self] (bounds) in
            guard let btn = self else { return }
            guard let label  = btn.titleLabel else { return }
            let imageSize = btn.imageView?.bounds.size ?? .zero
            let text = label.text ?? ""
            let titleSize = NSString(string: text).boundingRect(with: btn.bounds.size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: label.font], context: nil).size
            let totalWidth = imageSize.width + titleSize.width + spacing
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -(totalWidth - imageSize.width) * 2)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(totalWidth - titleSize.width) * 2, bottom: 0, right: 0)
        }
    }
            
    
    public func verticalCenterImageAndTitleWith(_ spacing: CGFloat) {
        setDidLayoutHandle { [weak self] (bounds) in
            guard let btn = self else { return }
            guard let label  = btn.titleLabel else { return }
            let imageSize = btn.imageView?.bounds.size ?? .zero
            let text = label.text ?? ""
            let titleSize = NSString(string: text).boundingRect(with: btn.bounds.size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: label.font], context: nil).size
            let totalHeight = imageSize.height + titleSize.height + spacing
            btn.imageEdgeInsets = UIEdgeInsets(top: -(totalHeight - imageSize.height), left: 0, bottom: 0, right: -titleSize.width)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width, bottom: -(totalHeight - titleSize.height), right: 0)
        }
    }
}
