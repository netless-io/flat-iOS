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
        viewControllers = [BaseNavigationViewController(rootViewController: HomeViewController())]
        super.loadView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if canShowDetail {
            // Show detail for device support split
            if viewControllers.count == 1 {
                showDetailViewController(emptyDetailController, sender: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .oneBesideSecondary
        delegate = self
    }
    
    func cleanSecondary() {
        if canShowDetail {
            showDetailViewController(.emptySplitSecondaryViewController(), sender: nil)
        }
    }
    
    lazy var emptyDetailController = EmptySplitSecondaryViewController()
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        // Wrap a navigation controller for split show a single vc
        if canShowDetail {
            if vc is UINavigationController {
                detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: sender)
                return false
            } else {
                showDetailViewController(BaseNavigationViewController(rootViewController: vc), sender: sender)
                return true
            }
        } else {
            detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: sender)
            return false
        }
    }
}
