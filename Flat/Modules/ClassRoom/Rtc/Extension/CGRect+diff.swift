//
//  CGRect+diff.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/8.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

extension CGRect {
    func isChangeLessThen(_ tolerance: CGFloat, from: CGRect) -> Bool {
        let dx = origin.x - from.origin.x
        let dy = origin.y - from.origin.y
        let dw = size.width - from.size.width
        let dh = size.height - from.size.height
        return abs(dx) <= tolerance &&
            abs(dy) <= tolerance &&
            abs(dw) <= tolerance &&
            abs(dh) <= tolerance
    }
}
