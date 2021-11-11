//
//  UIImage+Compose.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIImage {
    // Compose other image at center
    func compose(_ other: UIImage) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        draw(at: .zero)
        let otherSize = other.size
        let originX = (size.width - otherSize.width) / 2
        let originY = (size.height - otherSize.height) / 2
        let rect = CGRect(x: originX, y: originY, width: otherSize.width, height: otherSize.height)
        other.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
