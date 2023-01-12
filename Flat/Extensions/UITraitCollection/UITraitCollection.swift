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
    var isOnPadSplitScreen: Bool {
        let device = UIDevice.current
        if device.userInterfaceIdiom != .pad { return false }
        if !device.isMultitaskingSupported { return false }
        guard let windowBounds = view.window?.bounds else { return false }
        return windowBounds != UIScreen.main.bounds
    }
    
    var isOnPadSplitCompactScreen: Bool {
        if !isOnPadSplitScreen { return false }
        // Pad has no compact
        return isWindowCompact
    }
    
    var isWindowCompact: Bool {
        view.window?.traitCollection.hasCompact ?? true
    }
}
