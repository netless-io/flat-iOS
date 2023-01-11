//
//  TopViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit

func modalTopViewControllerFrom(root: UIViewController) -> UIViewController {
    if let present = root.presentedViewController {
        return modalTopViewControllerFrom(root: present)
    }
    return root
}

extension UIResponder {
    func viewController() -> UIViewController? {
        if let windowScene = self as? UIWindowScene {
            return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
        }
        
        var i: UIResponder? = self
        while (i != nil) {
            if let vc = i as? UIViewController { return vc }
            i = i?.next
        }
        return nil
    }
}

extension UIApplication {
    func topWith(windowScene: UIWindowScene?) -> UIViewController? {
        if let kw = windowScene?.windows.first(where: \.isKeyWindow) {
            return topWith(root: kw.rootViewController)
        }
        return nil
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
