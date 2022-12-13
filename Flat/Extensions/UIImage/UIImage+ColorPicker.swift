//
//  UIImage+ColorPicker.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIImage {
    static func pickerItemImage(withColor color: UIColor,
                                size: CGSize,
                                radius: CGFloat) -> UIImage?
    {
        let lineColor: CGColor = UIColor.black.withAlphaComponent(0.24).cgColor
        let lineWidth: CGFloat = commonBorderWidth
        let radius: CGFloat = radius
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let current = UIGraphicsGetCurrentContext()
        current?.setFillColor(color.cgColor)
        let pointRect = CGRect(origin: .zero, size: size)
        let bezeier = UIBezierPath(roundedRect: pointRect, cornerRadius: radius)
        current?.addPath(bezeier.cgPath)
        current?.fillPath()

        let strokeBezier = UIBezierPath(roundedRect: pointRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2), cornerRadius: radius)
        current?.beginPath()
        current?.addPath(strokeBezier.cgPath)
        current?.setLineWidth(lineWidth)
        current?.setStrokeColor(lineColor)
        current?.strokePath()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
