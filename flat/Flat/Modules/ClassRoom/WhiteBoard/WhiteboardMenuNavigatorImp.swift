//
//  WhiteboardMenuNavigatorImp.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Whiteboard
import UIKit

struct WhiteboardMenuNavigatorImp: WhiteboardMenuNavigator {
    weak var root: UIViewController?
    var tapSourceHandler: ((WhitePannelItem) -> UIView?)?
    let appliancePickerViewController = AppliancePickerViewController.init(operations: [], selectedIndex: nil)
    let strokePickerViewController: StrokePickerViewController
    
    func getNewApplianceObserver() -> Observable<WhiteApplianceNameKey> {
        appliancePickerViewController.newOperation.map { $0.appliance! }
    }
    
    func getColorAndWidthObserver() -> Observable<(UIColor, Float)> {
        let out = Observable.combineLatest(strokePickerViewController.selectedColor,
                                           strokePickerViewController.lineWidth)
            .distinctUntilChanged { i, j in
                return (i.0 == j.0) && (i.1 == j.1)
            }
        return out
    }
    
    func presentPicker(item: WhitePannelItem) {
        guard let root = root else { return }
        switch item {
        case .subops(ops: let ops, current: let current):
            appliancePickerViewController.operations.accept(ops)
            if let current = current {
                let index = ops.firstIndex(of: current) ?? 0
                appliancePickerViewController.selectedIndex.accept(index)
            } else {
                appliancePickerViewController.selectedIndex.accept(nil)
            }
        default:
            break
        }
        root.popoverViewController(viewController: appliancePickerViewController, fromSource: tapSourceHandler?(item))
    }
    
    
    func presentColorAndWidthPicker(item: WhitePannelItem, lineWidth: Float) {
        guard let root = root else { return }
        let color: UIColor
        if case .colorAndWidth(displayColor: let c) = item {
            color = c
        } else {
            color = .black
        }
        strokePickerViewController.updateCurrentColor(color, lineWidth: lineWidth)
        root.popoverViewController(viewController: strokePickerViewController, fromSource: tapSourceHandler?(item))
    }
}
