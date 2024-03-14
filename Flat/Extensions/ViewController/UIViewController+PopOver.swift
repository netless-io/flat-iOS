//
//  UIViewController+PopOver.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIPopoverArrowDirection {
    static var none: Self { .init(rawValue: 0) }
}

extension UIViewController {
    func popoverViewController(viewController: UIViewController,
                               fromSource sender: UIView?,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-15, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                               animated: Bool = true,
                               completion: (() -> Void)? = nil)
    {
        popoverViewController(viewController: viewController,
                              fromSource: sender,
                              fromItem: nil,
                              sourceBoundsInset: sourceBoundsInset,
                              permittedArrowDirections: permittedArrowDirections,
                              animated: animated,
                              completion: completion)
    }

    func popoverViewController(viewController: UIViewController,
                               fromItem item: UIBarButtonItem?,
                               sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-15, 0),
                               permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                               animated: Bool = true,
                               completion: (() -> Void)? = nil)
    {
        popoverViewController(viewController: viewController,
                              fromSource: nil,
                              fromItem: item,
                              sourceBoundsInset: sourceBoundsInset,
                              permittedArrowDirections: permittedArrowDirections,
                              animated: animated,
                              completion: completion)
    }

    private func popoverViewController(viewController: UIViewController,
                                       fromSource sender: UIView? = nil,
                                       fromItem item: UIBarButtonItem? = nil,
                                       sourceBoundsInset: (dx: CGFloat, dy: CGFloat) = (-15, 0),
                                       permittedArrowDirections: UIPopoverArrowDirection = .unknown,
                                       animated: Bool = true,
                                       completion: (() -> Void)? = nil)
    {
        if let presentedViewController {
            globalLogger.error("can't present when there is presented \(presentedViewController)")
            completion?()
            return
        }
        viewController.modalPresentationStyle = .popover
        if let view = sender {
            viewController.popoverPresentationController?.sourceView = view

            if permittedArrowDirections == .none {
                var isOnRight = true
                if let window = view.window {
                    let originInWindow = view.convert(CGPoint.zero, to: window)
                    isOnRight = originInWindow.x >= window.bounds.width / 2
                }

                if let navi = viewController as? UINavigationController, let root = navi.topViewController {
                    let xInset: CGFloat
                    if isOnRight {
                        xInset = (-root.preferredContentSize.width / 2) + sourceBoundsInset.dx
                    } else {
                        xInset = (viewController.preferredContentSize.width / 2) + (-sourceBoundsInset.dx) + view.bounds.width
                    }
                    viewController.popoverPresentationController?.sourceRect = .init(x: xInset, y: 0, width: 0, height: 0)
                } else {
                    let xInset: CGFloat
                    if isOnRight {
                        xInset = (-viewController.preferredContentSize.width / 2) + sourceBoundsInset.dx
                    } else {
                        xInset = (viewController.preferredContentSize.width / 2) + (-sourceBoundsInset.dx) + view.bounds.width
                    }
                    viewController.popoverPresentationController?.sourceRect = .init(x: xInset, y: 0, width: 0, height: 0)
                }
            } else {
                viewController.popoverPresentationController?.sourceRect = view.bounds.insetBy(dx: sourceBoundsInset.dx, dy: sourceBoundsInset.dy)
            }
        }
        if let item {
            viewController.popoverPresentationController?.barButtonItem = item
        }
        viewController.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        if viewController.popoverPresentationController?.delegate == nil {
            viewController.popoverPresentationController?.delegate = viewController
        }
        present(viewController, animated: animated, completion: completion)
    }
}
