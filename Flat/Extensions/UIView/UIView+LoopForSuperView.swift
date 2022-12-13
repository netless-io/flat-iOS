//
//  UIView+LoopForSuperView.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/30.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIView {
    func searchSuperViewForType<T>(_: T.Type) -> T? where T: UIView {
        var temp = superview
        while temp != nil {
            if let temp = temp, let tempT = temp as? T {
                return tempT
            }
            temp = temp?.superview
        }
        return nil
    }
}
