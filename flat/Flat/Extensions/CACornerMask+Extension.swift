//
//  CACornerMask.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension CACornerMask {
    static var all: CACornerMask {
        [.layerMinXMinYCorner, .layerMinXMaxYCorner,
         .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
    }
}
