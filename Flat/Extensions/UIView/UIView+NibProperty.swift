//
//  UIView+NibProperty.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    @IBInspectable open dynamic var radius: CGFloat {
        get { layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }

    @IBInspectable open dynamic var brdWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }

    @IBInspectable open dynamic var brdColor: UIColor? {
        get { layer.borderColor.map { UIColor(cgColor: $0) } }
        set { layer.borderColor = newValue?.cgColor }
    }
}
