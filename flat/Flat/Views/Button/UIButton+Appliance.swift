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
    func updateAppliance(_ appliance: WhiteApplianceNameKey) {
        let rawImage = UIImage(appliance: appliance)
        let disableImg = rawImage?.tintColor(.controlDisabled)
        setImage(disableImg, for: .disabled)
        
        let normalImg = rawImage?.tintColor(.controlNormal)
        setImage(normalImg, for: .normal)
        
        let highlightImg = rawImage?.tintColor(.controlSelected)
        setImage(highlightImg, for: .highlighted)
        
        let selectedImg = rawImage?.tintColor(.controlSelected, backgroundColor: .controlSelectedBG, cornerRadius: 5)
        setImage(selectedImg, for: .selected)
    }
}
