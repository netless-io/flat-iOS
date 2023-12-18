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

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = .color(light: .grey1, dark: UIColor(hexString: "#2B2F38"))
        
        if #available(iOS 14.0, *) {
            if ProcessInfo().isiOSAppOnMac {
                if !showHideElectronLink {
                    view.addSubview(linkToElectronView)
                    linkToElectronView.snp.makeConstraints { make in
                        make.left.right.bottom.equalToSuperview()
                        make.height.equalTo(33)
                    }
                }
            }
        }
    }
    
    var showHideElectronLink: Bool {
        get {
            UserDefaults.standard.bool(forKey: "showHideElectronLink")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "showHideElectronLink")
        }
    }
    
    lazy var linkToElectronView: UIView = {
        let strip = UIView(frame: .zero)
        let textView = UITextView()
        strip.addSubview(textView)
        let str = localizeStrings("ElectronLinkText")
        let attrStr = NSMutableAttributedString(string: str, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.color(type: .text)
        ])
        attrStr.add(link: "https://flat.whiteboard.agora.io/", forExistString: localizeStrings("Link"))
        textView.attributedText = attrStr
        textView.linkTextAttributes = [.foregroundColor: UIColor.color(type: .primary), .underlineColor: UIColor.clear]
        textView.isEditable = false
        textView.textAlignment = .center
        textView.backgroundColor = .color(type: .primary, .weak)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        strip.addSubview(closeButton)
        closeButton.imageEdgeInsets = .init(inset: 3)
        closeButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(44)
        }
        return strip
    }()
    
    lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "close-bold"), for: .normal)
        btn.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)
        btn.tintColor = UIColor.color(type: .text)
        return btn
    }()
    
    @objc func onClickClose() {
        linkToElectronView.removeFromSuperview()
        showHideElectronLink = true
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
                detailUpdateDelegate?.mainSplitViewControllerDidUpdateDetail(createEmptyDetailController(), sender: nil)
                setViewController(createEmptyDetailController(), for: .secondary)
            } else {
                show(createEmptyDetailController(), hidePrimary: false)
            }
        }
    }

    func createEmptyDetailController() -> EmptySplitSecondaryViewController { EmptySplitSecondaryViewController() }

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
