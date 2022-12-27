//
//  Global.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/30.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

let commonBorderWidth = 1 / UIScreen.main.scale

func fetchKeyWindow() -> UIWindow? {
    for scene in UIApplication.shared.connectedScenes {
        if let scene = scene as? UIWindowScene {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }
    }
    // When no key window was detected. Treat the first window as key window.
    for scene in UIApplication.shared.connectedScenes {
        if let scene = scene as? UIWindowScene {
            if let firstWindow = scene.windows.first {
                return firstWindow
            }
        }
    }
    return nil
}

func isCompact() -> Bool {
    fetchKeyWindow()?.traitCollection.hasCompact ?? true
}
