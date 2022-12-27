//
//  TopViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    var topViewController: UIViewController? {
        guard let rootViewController = fetchKeyWindow()?.rootViewController else { return nil }
        return topWith(root: rootViewController)
    }

    func topWith(root: UIViewController?) -> UIViewController? {
        if let split = root as? UISplitViewController {
            return topWith(root: split.viewControllers.last)
        }
        if let root = root as? UITabBarController {
            return topWith(root: root.selectedViewController)
        }
        if let root = root as? UINavigationController {
            return topWith(root: root.visibleViewController)
        }
        if let presented = root?.presentedViewController {
            return topWith(root: presented)
        }
        return root
    }
}
