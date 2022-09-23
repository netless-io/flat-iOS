//
//  UIView+TableViewHeader.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/23.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

extension UIView {
    static func minHeaderView() -> UIView {
        .init(frame: .init(x: 0, y: 0, width: 0, height: 0.001))
    }
}
