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
    @objc func show(_ vc: UIViewController, hidePrimary _: Bool = false) {
        showDetailViewController(vc, sender: nil)
    }
}

extension UIViewController {
    var mainContainer: MainContainer? {
        if let s = mainSplitViewController { return s }
        if let t = mainTabBarController { return t }
        return presentingViewController as? MainContainer
    }

    var mainTabBarController: MainTabBarController? {
        if let tabbar = self as? MainTabBarController {
            return tabbar
        }
        return navigationController?.tabBarController as? MainTabBarController
    }
    
    var mainSplitViewController: MainSplitViewController? {
        if let split = self as? MainSplitViewController {
            return split
        }
        if let vc = presentingViewController as? MainSplitViewController {
            return vc
        }
        return splitViewController as? MainSplitViewController
    }
}

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if traitCollection.hasCompact {
            return .portrait
        } else {
            return .all
        }
    }

    var canShowDetail: Bool {
        if #available(iOS 14.0, *) {
            if style == .unspecified { return false }
        }
        if isCollapsed || displayMode == .secondaryOnly { return false }
        return true
    }

    weak var detailUpdateDelegate: MainSplitViewControllerDetailUpdateDelegate?

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
        view.backgroundColor = .color(light: .grey1, dark: UIColor(hexString: "#2B2F38"))
    }

    override func show(_ vc: UIViewController, hidePrimary: Bool = false) {
        detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(vc, sender: nil)
        if #available(iOS 14.0, *) {
            if style == .tripleColumn {
                if let _ = vc as? UINavigationController {
                    setViewController(vc, for: .secondary)
                } else {
                    let targetVC = BaseNavigationViewController(rootViewController: vc)
                    setViewController(targetVC, for: .secondary)
                }
                if hidePrimary {
                    hide(.primary)
                }
            } else {
                showDetailViewController(vc, sender: nil)
            }
        } else {
            showDetailViewController(vc, sender: nil)
        }
    }

    func cleanSecondary() {
        if canShowDetail {
            if #available(iOS 14.0, *) {
                detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(emptyDetailController, sender: nil)
                setViewController(emptyDetailController, for: .secondary)
            } else {
                show(emptyDetailController, hidePrimary: false)
            }
        }
    }

    lazy var emptyDetailController = EmptySplitSecondaryViewController()

    func splitViewController(_: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        // Wrap a navigation controller for split show a single vc
        if canShowDetail {
            if vc is UINavigationController {
                return false
            } else {
                showDetailViewController(BaseNavigationViewController(rootViewController: vc), sender: sender)
                return true
            }
        } else {
            return false
        }
    }
}
