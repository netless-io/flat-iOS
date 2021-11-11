//
//  HomeTabbar.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/18.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class HomeTabbar: UITabBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        items?.forEach({ item in
            if let title = item.title, let attribute = item.titleTextAttributes(for: .normal) {
                let textHeight = NSString(string: title).size(withAttributes: attribute).height
                item.titlePositionAdjustment = .init(horizontal: 0, vertical: -((bounds.height - textHeight) / 2))
            }
        })
    }
    
    func setup() {
        backgroundColor = .white
        unselectedItemTintColor = .white
        backgroundImage = .imageWith(color: .white)
        shadowImage = .imageWith(color: .borderColor)
        selectionIndicatorImage = createSelectionIndicator(color: .brandColor,
                                                           size: .init(width: 44, height: 44),
                                                           lineHeight: 2)
    }
    
    func createSelectionIndicator(color: UIColor, size: CGSize, lineHeight: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(.init(x: 0, y: size.height - lineHeight, width: size.width, height: lineHeight))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func addItem(title: String,tag: Int) -> UITabBarItem {
        let item = UITabBarItem.init(title: title, image: nil, tag: tag)
        item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(hexString: "#A1A6AF").withAlphaComponent(0.5),
                                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium)], for: .normal)
        item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.text], for: .selected)
        return item
    }
}
