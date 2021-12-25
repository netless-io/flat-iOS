//
//  BaseNavigationViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class BaseNavigationViewController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        navigationBar.tintColor = .subText
    }
    
    override func show(_ vc: UIViewController, sender: Any?) {
        if let sender = sender as? Bool {
            pushViewController(vc, animated: sender)
        } else {
            pushViewController(vc, animated: true)
        }
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        super.popViewController(animated: animated)
    }
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if viewControllers.count > 1 {
            viewControllers.last?.hidesBottomBarWhenPushed = true
        }
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count == 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}
