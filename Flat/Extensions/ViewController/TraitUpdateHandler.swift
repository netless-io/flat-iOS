//
//  TraitUpdateHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/6.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

typealias TraitCollectionUpdateHandler = ((UITraitCollection?)->Void)

private var traitCollectionUpdateKey: Void?
extension UIViewController {
    var traitCollectionUpdateHandler: TraitCollectionUpdateHandler? {
        get {
            objc_getAssociatedObject(self, &traitCollectionUpdateKey) as? TraitCollectionUpdateHandler
        }
        set {
            objc_setAssociatedObject(self, &traitCollectionUpdateKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    @objc func exchangedTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.exchangedTraitCollectionDidChange(previousTraitCollection)
        traitCollectionUpdateHandler?(previousTraitCollection)
    }
}

extension UIView {
    var traitCollectionUpdateHandler: TraitCollectionUpdateHandler? {
        get {
            objc_getAssociatedObject(self, &traitCollectionUpdateKey) as? TraitCollectionUpdateHandler
        }
        set {
            objc_setAssociatedObject(self, &traitCollectionUpdateKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    @objc func exchangedTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.exchangedTraitCollectionDidChange(previousTraitCollection)
        traitCollectionUpdateHandler?(previousTraitCollection)
    }
}
