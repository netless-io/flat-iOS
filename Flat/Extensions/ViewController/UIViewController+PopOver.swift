//
//  UIViewController+PopOver.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIViewController {
    func popoverViewController(viewController: UIViewController,
                               fromSource sender: UIView?,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-10, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                          animated: Bool = true) {
        popoverViewController(viewController: viewController,
                              fromSource: sender,
                              fromItem: nil,
                              sourceBoundsInset: sourceBoundsInset,
                              permittedArrowDirections: permittedArrowDirections,
                              animated: animated)
    }
    
    func popoverViewController(viewController: UIViewController,
                               fromItem item: UIBarButtonItem?,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-10, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                               animated: Bool = true) {
        popoverViewController(viewController: viewController,
                              fromSource: nil,
                              fromItem: item,
                              sourceBoundsInset: sourceBoundsInset,
                              permittedArrowDirections: permittedArrowDirections,
                              animated: animated)
    }
    
    fileprivate func popoverViewController(viewController: UIViewController,
                               fromSource sender: UIView? = nil,
                               fromItem item: UIBarButtonItem? = nil,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-10, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                               animated: Bool = true) {
        viewController.modalPresentationStyle = .popover
        if let view = sender {
            viewController.popoverPresentationController?.sourceView = view
            viewController.popoverPresentationController?.sourceRect = view.bounds.insetBy(dx: sourceBoundsInset.dx, dy: sourceBoundsInset.dy)
        }
        if let item = item {
            viewController.popoverPresentationController?.barButtonItem = item
        }
        viewController.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        if let popoverDelegate = viewController as? UIPopoverPresentationControllerDelegate {
            viewController.popoverPresentationController?.delegate = popoverDelegate
        } else {
            let autoGeneratedDelegate = AnyPopOverDelegate(adaptivePresentationStyleAdaptor: { _, _ in
                return .none
            })
            viewController.anyPopOverDelegate = autoGeneratedDelegate
            viewController.popoverPresentationController?.delegate = autoGeneratedDelegate
        }
        present(viewController, animated: animated, completion: nil)
    }
}
