//
//  UIColor+FlatTheme.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/5.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

extension UIColor {
    fileprivate static var nameSuffix: String {
        Theme.shared.isDarkBeforeIOS13 ? "-dark" : ""
    }
    
}
