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
    internal init(root: UIViewController? = nil, clickToDismiss: Bool, tapSourceHandler: ((WhitePanelItem) -> UIView?)? = nil) {
        self.root = root
        self.tapSourceHandler = tapSourceHandler
        let avc = AppliancePickerViewController.init(operations: [], selectedIndex: nil)
        avc.clickToDismiss = clickToDismiss
        self.appliancePickerViewController = avc
        
        let svc = StrokePickerViewController(candidateColors: WhiteboardPanelConfig.defaultColors)
        svc.clickToDismiss = clickToDismiss
        self.strokePickerViewController = svc
    }
    
    weak var root: UIViewController?
    var tapSourceHandler: ((WhitePanelItem) -> UIView?)?
    let appliancePickerViewController: AppliancePickerViewController
    let strokePickerViewController: StrokePickerViewController
    
    func getNewOperationObserver() -> Observable<WhiteboardPanelOperation> {
        appliancePickerViewController.newOperation.asObservable()
    }
    
    func getColorAndWidthObserver() -> Observable<(UIColor, Float)> {
        let out = Observable.combineLatest(strokePickerViewController.selectedColor,
                                           strokePickerViewController.lineWidth)
            .distinctUntilChanged { i, j in
                return (i.0 == j.0) && (i.1 == j.1)
            }
        return out
    }
    
    func presentPicker(item: WhitePanelItem) {
        guard let root = root else { return }
        switch item {
        case .subOps(ops: let ops, current: let current):
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
    
    
    func presentColorAndWidthPicker(item: WhitePanelItem, lineWidth: Float) {
        guard let root = root else { return }
        let color: UIColor
        if case .color(displayColor: let c) = item {
            color = c
        } else {
            color = .black
        }
        strokePickerViewController.updateCurrentColor(color, lineWidth: lineWidth)
        root.popoverViewController(viewController: strokePickerViewController, fromSource: tapSourceHandler?(item))
    }
}
