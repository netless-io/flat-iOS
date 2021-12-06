//
//  MethodExchange.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/6.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import ObjectiveC

func methodExchange(cls: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
    let original = class_getInstanceMethod(cls, originalSelector)!
    let target = class_getInstanceMethod(cls, swizzledSelector)!
    method_exchangeImplementations(original, target)
}
