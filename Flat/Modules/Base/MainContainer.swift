//
//  MainContainer.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/24.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

protocol MainContainer: AnyObject {
    func push(_ vc: UIViewController)
    
    func pushOnSplitPresentOnCompact(_ vc: UIViewController)
    
    func removeTop()
    
    var concreteViewController: UIViewController { get }
}

extension MainContainer where Self: UIViewController {
    var concreteViewController: UIViewController { self }
}

extension MainTabBarController: MainContainer {
    func removeTop() {
        (selectedViewController as? UINavigationController)?.popViewController(animated: true)
    }
    
    func pushOnSplitPresentOnCompact(_ vc: UIViewController) {
        present(vc, animated: true, completion: nil)
    }
    
    func push(_ vc: UIViewController) {
        (selectedViewController as? UINavigationController)?.pushViewController(vc, animated: true)
    }
    
    func cleanSecondary() {}
}

extension MainSplitViewController: MainContainer {
    func removeTop() {
        cleanSecondary()
    }
    
    func pushOnSplitPresentOnCompact(_ vc: UIViewController) {
        push(vc)
    }
    
    func push(_ vc: UIViewController) {
        show(vc)
    }
}
