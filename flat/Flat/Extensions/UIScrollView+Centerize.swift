//
//  UIScrollView+Centerize.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/30.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIScrollView {
    func centerize(_ view: UIView, animated: Bool) {
        let center = view.convert(CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2), to: self)
        let offset = CGPoint(x: center.x - (bounds.width / 2), y: center.y - (bounds.height / 2))
        let minusMaxX = min(max(0, offset.x), contentSize.width - bounds.width)
        let minusMaxY = min(max(0, offset.y), contentSize.height)
        let minusMaxOffset = CGPoint(x: minusMaxX, y: minusMaxY)
        setContentOffset(minusMaxOffset, animated: animated)
    }
}
