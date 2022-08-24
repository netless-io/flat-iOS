//
//  UIColor+Theme.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/25.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIColor {
    fileprivate static var nameSuffix: String {
        Theme.shared.isDarkBeforeIOS13 ? "-dark" : ""
    }
    
    static var emptyViewIconTintColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait in
                return trait.userInterfaceStyle == .dark ? .init(hexString: "#747474") : .init(hexString: "#F3F6F9")
            }
        } else {
            return nameSuffix.isEmpty ? .init(hexString: "#747474") : .init(hexString: "#F3F6F9")
        }
    }
    
    static var cellSelectedBG: UIColor {
        return UIColor(named: "CellSelectedBG" + nameSuffix)!
    }
    
    static var controlDisabled: UIColor {
        return UIColor(named: "ControlDisable" + nameSuffix)!
    }
    
    static var controlNormal: UIColor {
        return UIColor(named:"ControlNormal" + nameSuffix)!
    }
    
    static var controlSelected: UIColor {
        return UIColor(named:"ControlSelected" + nameSuffix)!
    }
    
    static var popoverBorder: UIColor {
        return UIColor(named:"PopoverBorder" + nameSuffix)!
    }
    
    static var borderColor: UIColor {
        return UIColor(named:"BorderColor" + nameSuffix)!
    }
    
    static var brandColor: UIColor {
        return UIColor(named:"BrandColor" + nameSuffix)!
    }
    
    static var brandStrongColor: UIColor {
        return UIColor(named:"BrandColor-strong" + nameSuffix)!
    }
    
    static var controlSelectedBG: UIColor {
        return UIColor(named:"ControlSelectedBG" + nameSuffix)!
    }
    
    static var text: UIColor {
        return UIColor(named:"Text" + nameSuffix)!
    }
    
    static var strongText: UIColor {
        return UIColor(named:"Text-strong" + nameSuffix)!
    }
    
    static var whiteText: UIColor {
        return UIColor(named:"Text-White" + nameSuffix)!
    }
    
    static var disableText: UIColor {
        return UIColor(named:"Text-disable" + nameSuffix)!
    }
    
    static var subText: UIColor {
        return UIColor(named:"SubText" + nameSuffix)!
    }
    
    static var commonBG: UIColor {
        return UIColor(named: "GrayBGColor" + nameSuffix)!
    }
    
    static var separateLine: UIColor {
        return UIColor(named: "separateLine" + nameSuffix)!
    }
    
    static var blackBG: UIColor {
        return UIColor(named: "blackBG" + nameSuffix)!
    }
    
    static var whiteBG: UIColor {
        return UIColor(named: "whiteBG" + nameSuffix)!
    }
    
    static var lightBlueBar: UIColor {
        return UIColor(named: "LightBlueBar" + nameSuffix)!
    }
    
    static var sideBarNormal: UIColor {
        return UIColor(named: "SideBarNormal" + nameSuffix)!
    }
    
    static var sideBarSelected: UIColor {
        return UIColor(named: "SideBarSelected" + nameSuffix)!
    }
    
    static var sideBarTextNormal: UIColor {
        return UIColor(named: "SideBarTextNormal" + nameSuffix)!
    }
    
    static var sideBarTextSelected: UIColor {
        return UIColor(named: "SideBarTextSelected" + nameSuffix)!
    }
}
