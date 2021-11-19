//
//  PopOverDismissDetectableViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

// Set popoverPresentationController?.delegate to self, to make sure the dismiss be notified
class PopOverDismissDetectableViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    var dismissHandler: (()->Void)?
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissHandler?()
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissHandler?()
    }
}
