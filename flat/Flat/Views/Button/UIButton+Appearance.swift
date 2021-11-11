//
//  UIButton+Appliance.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard
import UIKit

extension UIButton {
    static func buttonWithClassRoomStyle(withImage image: UIImage) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image.tintColor(.controlNormal), for: .normal)
        button.setImage(image.tintColor(.controlSelected), for: .selected)
        return button
    }
}
