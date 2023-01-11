//
//  UITraitCollection.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/20.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UITraitCollection {
    var hasCompact: Bool {
        verticalSizeClass == .compact || horizontalSizeClass == .compact
    }
}

extension UIViewController {
    var isWindowCompact: Bool {
        view.window?.traitCollection.hasCompact ?? true
    }
}
