//
//  FlatCustomAlertSetable.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/29.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

@objc
protocol FlatCustomAlertSetable: AnyObject {
    @available(iOS 14.0, *)
    var menu: UIMenu? { get  set }
    var viewContainingControllerProvider: (()->UIViewController?)? { get set }
    func viewContainingController() -> UIViewController?
    func addTarget(_ target: AnyObject?, action: Selector)
    @available(iOS 14.0, *)
    func _buildMenu()
    @objc func _onClickCommonCustomAlert()
}

extension UIButton: FlatCustomAlertSetable {
    var viewContainingControllerProvider: (() -> UIViewController?)? {
        get {
            nil
        }
        set {
        }
    }
    
    func _buildMenu() {
        if #available(iOS 14.0, *) {
            showsMenuAsPrimaryAction = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    func _onClickCommonCustomAlert() {
        if #available(iOS 13.0, *) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        viewContainingController()?.presentCommonCustomAlert(actions)
    }
    
    func addTarget(_ target: AnyObject?, action: Selector) {
        addTarget(target, action: action, for: .touchUpInside)
    }
}

private var viewContainingControllerProviderKey: Void?
extension UIBarButtonItem: FlatCustomAlertSetable {
    var viewContainingControllerProvider: (() -> UIViewController?)? {
        get {
            objc_getAssociatedObject(self, &viewContainingControllerProviderKey) as? (() -> UIViewController?)
        }
        set {
            objc_setAssociatedObject(self, &viewContainingControllerProviderKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    func viewContainingController() -> UIViewController? {
        viewContainingControllerProvider?()
    }
    
    func addTarget(_ target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }
    
    func _buildMenu() {
    }
    
    func _onClickCommonCustomAlert() {
        viewContainingController()?.presentCommonCustomAlert(actions)
    }
}

private var customActionsKey: Void?
extension FlatCustomAlertSetable {
    fileprivate var actions: [Action] {
        get {
            (objc_getAssociatedObject(self, &customActionsKey) as? [Action]) ?? []
        }
        set {
            objc_setAssociatedObject(self, &customActionsKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    func setupCommonCustomAlert(title: String? = nil, _ actions: [Action]) {
        guard let trait = UIApplication.shared.keyWindow?.traitCollection else { return }
        if trait.hasCompact {
            self.actions = actions
            addTarget(self, action: #selector(_onClickCommonCustomAlert))
        } else {
            if #available(iOS 14.0, *) {
                let systemActions: [UIAction] = actions.compactMap { action -> UIAction? in
                    if action.isCancelAction() { return nil }
                    let realAction = UIAction(title: action.title,
                                              image: action.image,
                                              attributes: action.style == .destructive ? .destructive : []) { _ in
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        action.handler?(action)
                    }
                    return realAction
                }
                menu = UIMenu.init(title: title ?? "",
                                   image: nil,
                                   identifier: nil,
                                   children: systemActions)
                _buildMenu()
            } else {
                self.actions = actions
                addTarget(self, action: #selector(_onClickCommonCustomAlert))
            }
        }
    }
}

extension UIViewController {
    func presentCommonCustomAlert(_ actions: [Action]) {
        let vc = FlatCompactAlertController(actions)
        mainContainer?.concreteViewController.present(vc, animated: true)
    }
    
    func popOverCommonCustomAlert(_ actions: [Action], fromSource: UIView?, permittedArrowDirections: UIPopoverArrowDirection = .unknown) {
        let vc = FlatPopoverAlertController(actions)
        mainContainer?.concreteViewController.popoverViewController(viewController: vc, fromSource: fromSource, permittedArrowDirections: permittedArrowDirections)
    }
}
