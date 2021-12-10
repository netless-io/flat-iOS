//
//  MainSplitViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

protocol MainSplitViewControllerDetailUpdateDelegate: AnyObject {
    func mainSplitViewControllerDidUpdateDetail(_ vc: UIViewController, sender: Any?)
}

extension UISplitViewController {
    /// hidePrimary will only effect when style is triple column
    @objc func show(_ vc: UIViewController, hidePrimary: Bool = true) {
        showDetailViewController(vc, sender: nil)
    }
}

extension UIViewController {
    var mainSplitViewController: MainSplitViewController? {
        splitViewController as? MainSplitViewController
    }
}

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    var canShowDetail: Bool {
        if isCollapsed || displayMode == .secondaryOnly { return false }
        return true
    }
    
    weak var detailUpdateDelegate: MainSplitViewControllerDetailUpdateDelegate?
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if canShowDetail {
            // Show detail for device support split
            if viewControllers.count == 1 {
                show(emptyDetailController)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    override func show(_ vc: UIViewController, hidePrimary: Bool = true) {
        detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: nil)
        if #available(iOS 14.0, *) {
            if let _ = vc as? UINavigationController {
                setViewController(vc, for: .secondary)
            } else {
                let targetVC = BaseNavigationViewController(rootViewController: vc)
                setViewController(targetVC, for: .secondary)
            }
            if hidePrimary {
                show(.secondary)
            }
        } else {
            showDetailViewController(vc, sender: nil)
        }
    }
    
    func cleanSecondary() {
        if canShowDetail {
            show(emptyDetailController, hidePrimary: false)
        }
    }
    
    lazy var emptyDetailController = EmptySplitSecondaryViewController()
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        // Wrap a navigation controller for split show a single vc
        if canShowDetail {
            if vc is UINavigationController {
//                detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: sender)
                return false
            } else {
                showDetailViewController(BaseNavigationViewController(rootViewController: vc), sender: sender)
                return true
            }
        } else {
//            detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: sender)
            return false
        }
    }
}
