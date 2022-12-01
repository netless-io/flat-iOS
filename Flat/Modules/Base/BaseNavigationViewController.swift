//
//  BaseNavigationViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class BaseNavigationViewController: UINavigationController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateNaviAppearance()
    }
    
    override var description: String {
        "BaseNavigationViewController: \(children.map { $0.description }.joined(separator: "-"))"
    }
    
    func updateNaviAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .color(type: .background, .weak)
            appearance.setBackIndicatorImage(UIImage(named: "arrowLeft"),
                                             transitionMaskImage: UIImage(named: "arrowLeft"))
            appearance.shadowImage = UIImage.imageWith(color: .borderColor)
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().setBackgroundImage(UIImage.imageWith(color: .color(type: .background)), for: .default)
            UINavigationBar.appearance().backgroundColor = .color(type: .background)
            UINavigationBar.appearance().backIndicatorImage = UIImage(named: "arrowLeft")
            UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "arrowLeft")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
        updateNaviAppearance()
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
        if #available(iOS 14.0, *) {
            viewController.navigationItem.backButtonDisplayMode = .minimal
        } else {
            let back = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
            viewController.navigationItem.backBarButtonItem = back
        }
        if viewControllers.count == 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}

extension BaseNavigationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
