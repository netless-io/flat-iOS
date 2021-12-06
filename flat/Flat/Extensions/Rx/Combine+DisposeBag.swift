//
//  Combine+DisposeBag.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Combine

@available(iOS 13.0, *)
extension UIViewController {
    private static var cancellableKey: Bool = false
    
    public var disposeBag: DisposeBag! {
        set {
            objc_setAssociatedObject(self, &UIViewController.cancellableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &UIViewController.cancellableKey) as? DisposeBag) ?? DisposeBag()
        }
    }
}

@available(iOS 13.0, *)
extension UIView {
    private static var cancellableKey: Bool = false
    
    public var disposeBag: DisposeBag! {
        set {
            objc_setAssociatedObject(self, &UIView.cancellableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &UIView.cancellableKey) as? DisposeBag) ?? DisposeBag()
        }
    }
}

@available(iOS 13.0, *)
public class DisposeBag: NSObject {
    private let lock = NSLock()
    private var cancellableSet = Set<AnyCancellable>()
    
    func store(_ cancellable: AnyCancellable) {
        lock.lock()
        cancellableSet.insert(cancellable)
        lock.unlock()
    }

    func drop(_ cancellable: AnyCancellable) {
        lock.lock()
        cancellableSet.remove(cancellable)
        lock.unlock()
    }
    
    deinit {
        cancellableSet.removeAll()
    }
}

@available(iOS 13.0, *)
extension AnyCancellable {
    final public func store(in bag: inout DisposeBag) {
        bag.store(self)
    }

    final public func cancel(in bag: inout DisposeBag) {
        bag.drop(self)
    }
}

@available(iOS 13.0, *)
extension Set where Element: AnyCancellable {
    public func store(in bag: inout DisposeBag) {
        forEach { (element) in
            bag.store(element)
        }
    }
}
