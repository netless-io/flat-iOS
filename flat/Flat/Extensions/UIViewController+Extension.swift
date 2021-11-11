//
//  UIViewController+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIViewController {
    func popoverViewController(viewController: UIViewController,
                               fromSource sender: UIView,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-10, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                               animated: Bool = true) {
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = sender
        viewController.popoverPresentationController?.sourceRect = sender.bounds.insetBy(dx: sourceBoundsInset.dx, dy: sourceBoundsInset.dy)
        viewController.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        if let popoverDelegate = viewController as? UIPopoverPresentationControllerDelegate {
            viewController.popoverPresentationController?.delegate = popoverDelegate
        }
        present(viewController, animated: animated, completion: nil)
    }
}
