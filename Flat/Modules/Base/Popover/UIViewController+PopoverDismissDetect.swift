//
//  PopOverDismissDetectableViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

private var popOverDismissHandlerKey: Void?

// Set popoverPresentationController?.delegate to self, to make sure the dismiss be notified
extension UIViewController: UIPopoverPresentationControllerDelegate {
    typealias PopOverDismissHandler = ()->Void
    var popOverDismissHandler: PopOverDismissHandler? {
        get {
            objc_getAssociatedObject(self, &popOverDismissHandlerKey) as? PopOverDismissHandler
        }
        set {
            objc_setAssociatedObject(self, &popOverDismissHandlerKey, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if let style = adaptivePresentationStyleAdaptor?(controller, traitCollection) {
            return style
        } else {
            return .none
        }
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        popOverDismissHandler?()
    }
    
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        popOverDismissHandler?()
    }
}
