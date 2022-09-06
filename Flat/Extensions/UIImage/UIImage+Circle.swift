//
//  UIImage+Circle.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIImage {
    static func circleImage() -> UIImage {
        UIImage(named: "circle")!.tintColor(.borderColor)
    }
    
    static func filledCircleImage(radius: CGFloat,
                                  bigLineWidth: CGFloat = 1) -> UIImage {
        let path = UIBezierPath(arcCenter: .init(x: radius, y: radius),
                                radius: radius - bigLineWidth,
                                startAngle: 0,
                                endAngle: CGFloat.pi * 2,
                                clockwise: true)
        let center = UIBezierPath(arcCenter: .init(x: radius, y: radius),
                                  radius: radius - 4,
                                  startAngle: 0,
                                  endAngle: CGFloat.pi * 2,
                                  clockwise: true)
        let size = CGSize(width: radius * 2, height: radius * 2)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        UIColor.color(type: .primary).setStroke()
        context?.setLineWidth(bigLineWidth)
        context?.addPath(path.cgPath)
        context?.strokePath()
        
        UIColor.color(type: .primary).setFill()
        context?.addPath(center.cgPath)
        context?.fillPath()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}
