//
//  UIImage+Color.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIImage {
    class func imageWith(color: UIColor, size: CGSize = .init(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let current = UIGraphicsGetCurrentContext()
        current?.setFillColor(color.cgColor)
        current?.fill(.init(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    class func pointWith(color: UIColor, size: CGSize, radius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let current = UIGraphicsGetCurrentContext()
        current?.setFillColor(color.cgColor)
        let bezeier = UIBezierPath(roundedRect: .init(origin: .zero, size: size), cornerRadius: radius)
        current?.addPath(bezeier.cgPath)
        current?.fillPath()
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
