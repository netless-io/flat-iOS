//
//  UIImage+Appliance.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard

extension UIImage {
    convenience init?(appliance: WhiteApplianceNameKey) {
        self.init(named: "whiteboard_\(appliance.rawValue)")
    }
}
