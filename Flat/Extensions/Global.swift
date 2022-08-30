//
//  Global.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/30.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

func isCompact() -> Bool {
    if #available(iOS 13.0, *) {
        for scene in UIApplication.shared.connectedScenes {
            if let scene = scene as? UIWindowScene {
                if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                    return keyWindow.traitCollection.hasCompact
                }
            }
        }
    } else {
        if let has = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.traitCollection.hasCompact {
            return has
        }
    }
    return true
}
