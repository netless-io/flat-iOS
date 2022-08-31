//
//  UIImage+oldDark.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/31.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

extension UIImage {
    fileprivate static var nameSuffix: String {
        Theme.shared.isDarkBeforeIOS13 ? "-dark" : ""
    }
    
    convenience init?(dynamicName: String) {
        self.init(named: dynamicName + Self.nameSuffix)
    }
}

extension UIImageView {
    func setDynamicImage(dynamicName: String) {
        image = UIImage(dynamicName: dynamicName)
        traitCollectionUpdateHandler = { [weak self] _ in
            self?.image = UIImage(dynamicName: dynamicName)
        }
    }
}
