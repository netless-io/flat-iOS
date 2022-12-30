//
//  UIImage+tintColor.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/25.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIImage {
    func tintColor(_ color: UIColor,
                   backgroundColor: UIColor? = nil,
                   cornerRadius: CGFloat = 0,
                   backgroundEdgeInset: UIEdgeInsets = .zero) -> UIImage
    {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        var bg: UIImage?
        // Draw background
        if let bgColor = backgroundColor {
            context?.setFillColor(bgColor.cgColor)
            let bgRect = rect.inset(by: backgroundEdgeInset)
            let path = UIBezierPath(roundedRect: bgRect, cornerRadius: cornerRadius)
            path.fill()
            context?.fillPath()
            bg = UIGraphicsGetImageFromCurrentImageContext()
            context?.clear(rect)
        }
        // Draw icon
        draw(in: rect)
        color.set()
        UIRectFillUsingBlendMode(rect, .sourceAtop)
        let icon = UIGraphicsGetImageFromCurrentImageContext()
        context?.clear(rect)
        // Compose
        bg?.draw(in: rect)
        icon?.draw(in: rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!.withRenderingMode(.alwaysOriginal)
    }
}
