//
//  RtcItemVideoContainer.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/9.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class RtcItemVideoContainer: UIView {
    override var frame: CGRect {
        didSet {
            // Warning: update view's frame when the view is directly on the window hierachy will not trigger `layoutSubviews` function.
            self.subviews.forEach { $0.frame = self.bounds }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.frame = bounds }
    }
}
