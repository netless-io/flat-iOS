//
//  UIColor+Level.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/5.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var blues: [String] = [
        "#F4F8FF",
        "#EBF2FF",
        "#D6E5FF",
        "#ADCCFF",
        "#84B3FF",
        "#5B9AFF",
        "#3381FF",
        "#2867CC",
        "#1E4D99",
        "#143366",
        "#0A1933",
        "#050D1A",
        "#03060D"
    ]
    
    static var greys: [String] = [
        "#ECF0F7",
        "#E5E8F0",
        "#D5D9E0",
        "#B7BBC1",
        "#999CA3",
        "#7B7E84",
        "#5D6066",
        "#4B4D54",
        "#383B42",
        "#272A30",
        "#14181E",
        "#070A11",
        "#03060D"
    ]
    
    static var greens: [String] = [
        "#F5FAF2",
        "#ECF6E6",
        "#D9EECC",
        "#B4DE99",
        "#8ECD66",
        "#69BD33",
        "#44AD00",
        "#368B00",
        "#296800",
        "#1B4500",
        "#0E2300",
        "#071100",
        "#030900"
    ]
    
    static var yellows: [String] = [
        "#FDF9F2",
        "#FCF4E6",
        "#FAEACC",
        "#F5D599",
        "#F1C166",
        "#ECAC33",
        "#E89800",
        "#BA7A00",
        "#8B5B00",
        "#5C3C00",
        "#2E1E00",
        "#170F00",
        "#0C0800"
    ]
    
    static var reds: [String] = [
        "#FCF3F2",
        "#FAE9E6",
        "#F6D2CC",
        "#EDA599",
        "#E47866",
        "#DB4B33",
        "#D21F00",
        "#A81800",
        "#7E1300",
        "#540C00",
        "#2A0600",
        "#150300",
        "#0A0200"
    ]
    
    static var blue0 = UIColor.init(hexString: UIColor.blues[0])
    static var blue1 = UIColor.init(hexString: UIColor.blues[1])
    static var blue2 = UIColor.init(hexString: UIColor.blues[2])
    static var blue3 = UIColor.init(hexString: UIColor.blues[3])
    static var blue4 = UIColor.init(hexString: UIColor.blues[4])
    static var blue5 = UIColor.init(hexString: UIColor.blues[5])
    static var blue6 = UIColor.init(hexString: UIColor.blues[6])
    static var blue7 = UIColor.init(hexString: UIColor.blues[7])
    static var blue8 = UIColor.init(hexString: UIColor.blues[8])
    static var blue9 = UIColor.init(hexString: UIColor.blues[9])
    static var blue10 = UIColor.init(hexString: UIColor.blues[10])
    static var blue11 = UIColor.init(hexString: UIColor.blues[11])
    static var blue12 = UIColor.init(hexString: UIColor.blues[12])
    
    static var grey0 = UIColor.init(hexString: UIColor.greys[0])
    static var grey1 = UIColor.init(hexString: UIColor.greys[1])
    static var grey2 = UIColor.init(hexString: UIColor.greys[2])
    static var grey3 = UIColor.init(hexString: UIColor.greys[3])
    static var grey4 = UIColor.init(hexString: UIColor.greys[4])
    static var grey5 = UIColor.init(hexString: UIColor.greys[5])
    static var grey6 = UIColor.init(hexString: UIColor.greys[6])
    static var grey7 = UIColor.init(hexString: UIColor.greys[7])
    static var grey8 = UIColor.init(hexString: UIColor.greys[8])
    static var grey9 = UIColor.init(hexString: UIColor.greys[9])
    static var grey10 = UIColor.init(hexString: UIColor.greys[10])
    static var grey11 = UIColor.init(hexString: UIColor.greys[11])
    static var grey12 = UIColor.init(hexString: UIColor.greys[12])
    
    static var green0 = UIColor.init(hexString: UIColor.greens[0])
    static var green1 = UIColor.init(hexString: UIColor.greens[1])
    static var green2 = UIColor.init(hexString: UIColor.greens[2])
    static var green3 = UIColor.init(hexString: UIColor.greens[3])
    static var green4 = UIColor.init(hexString: UIColor.greens[4])
    static var green5 = UIColor.init(hexString: UIColor.greens[5])
    static var green6 = UIColor.init(hexString: UIColor.greens[6])
    static var green7 = UIColor.init(hexString: UIColor.greens[7])
    static var green8 = UIColor.init(hexString: UIColor.greens[8])
    static var green9 = UIColor.init(hexString: UIColor.greens[9])
    static var green10 = UIColor.init(hexString: UIColor.greens[10])
    static var green11 = UIColor.init(hexString: UIColor.greens[11])
    static var green12 = UIColor.init(hexString: UIColor.greens[12])
    
    static var yellow0 = UIColor.init(hexString: UIColor.yellows[0])
    static var yellow1 = UIColor.init(hexString: UIColor.yellows[1])
    static var yellow2 = UIColor.init(hexString: UIColor.yellows[2])
    static var yellow3 = UIColor.init(hexString: UIColor.yellows[3])
    static var yellow4 = UIColor.init(hexString: UIColor.yellows[4])
    static var yellow5 = UIColor.init(hexString: UIColor.yellows[5])
    static var yellow6 = UIColor.init(hexString: UIColor.yellows[6])
    static var yellow7 = UIColor.init(hexString: UIColor.yellows[7])
    static var yellow8 = UIColor.init(hexString: UIColor.yellows[8])
    static var yellow9 = UIColor.init(hexString: UIColor.yellows[9])
    static var yellow10 = UIColor.init(hexString: UIColor.yellows[10])
    static var yellow11 = UIColor.init(hexString: UIColor.yellows[11])
    static var yellow12 = UIColor.init(hexString: UIColor.yellows[12])
    
    static var red0 = UIColor.init(hexString: UIColor.reds[0])
    static var red1 = UIColor.init(hexString: UIColor.reds[1])
    static var red2 = UIColor.init(hexString: UIColor.reds[2])
    static var red3 = UIColor.init(hexString: UIColor.reds[3])
    static var red4 = UIColor.init(hexString: UIColor.reds[4])
    static var red5 = UIColor.init(hexString: UIColor.reds[5])
    static var red6 = UIColor.init(hexString: UIColor.reds[6])
    static var red7 = UIColor.init(hexString: UIColor.reds[7])
    static var red8 = UIColor.init(hexString: UIColor.reds[8])
    static var red9 = UIColor.init(hexString: UIColor.reds[9])
    static var red10 = UIColor.init(hexString: UIColor.reds[10])
    static var red11 = UIColor.init(hexString: UIColor.reds[11])
    static var red12 = UIColor.init(hexString: UIColor.reds[12])
}

enum ColorStrenth: Int {
    case weaker
    case weak
    case normal
    case strong
    case stronger
}

enum ColorType: Int {
    case primary
    case danger
    case success
    case warning
    case text
    case background
}

let colorTable: [ColorType: [ColorStrenth: UIColor]] = [
    .primary: [.weaker: .blue0,
               .weak: .blue1,
               .normal: .blue6,
               .strong: .blue7,
               .stronger: .blue8,
    ],
    .danger: [.weaker: .red2,
              .weak: .red5,
              .normal: .red6,
              .strong: .red7,
              .stronger: .red8,
    ],
    .success: [.weaker: .green2,
               .weak: .green5,
               .normal: .green6,
               .strong: .green7,
               .stronger: .green8,
    ],
    .warning: [.weaker: .yellow2,
               .weak: .yellow5,
               .normal: .yellow6,
               .strong: .yellow7,
               .stronger: .yellow8,
    ],
    .text: [.weak: .grey3,
            .normal: .grey6,
            .strong: .grey12
    ],
    .background: [
        .weak: .white,
        .normal: .white,
        .strong: .init(hexString: "#F9F9F9")
    ]
]

let darkColorTable: [ColorType: [ColorStrenth: UIColor]] = [
    .primary: [.weaker: .grey7,
               .weak: .grey8,
               .normal: .blue7,
               .strong: .blue6,
               .stronger: .blue0,
    ],
    .danger: [.weaker: .red10,
              .weak: .red8,
              .normal: .red7,
              .strong: .red6,
              .stronger: .red2,
    ],
    .success: [.weaker: .green10,
               .weak: .green8,
               .normal: .green7,
               .strong: .green6,
               .stronger: .green2,
    ],
    .warning: [.weaker: .yellow10,
               .weak: .yellow8,
               .normal: .yellow7,
               .strong: .yellow6,
               .stronger: .yellow2,
    ],
    .text: [.weak: .grey6,
            .normal: .grey3,
            .strong: .grey0,
    ],
    .background: [
        .weak: .init(hexString: "#222429"),
        .normal: .grey9,
        .strong: .grey7
    ]
]

extension UIColor {
    static func color(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { t in
                switch t.userInterfaceStyle {
                case .dark:
                    return dark
                case .light, .unspecified:
                    return light
                @unknown default:
                    return light
                }
            }
        } else {
            if Theme.shared.isDarkBeforeIOS13 {
                return dark
            } else {
                return light
            }
        }
    }
    
    static func color(type: ColorType, _ strenth: ColorStrenth = .normal) -> UIColor {
        color(light: colorTable[type]![strenth]!, dark: darkColorTable[type]![strenth]!)
    }
    
    static var borderColor: UIColor {
        color(light: .grey1, dark: grey8)
    }
    
    static var whiteBG: UIColor {
        color(light: .white, dark: .grey11)
    }
    
    static var classroomChildBG: UIColor {
        color(light: .white, dark: .grey7)
    }
    
    static var whiteText: UIColor {
        color(light: .white, dark: .blue0)
    }
    
    static var customAlertBg: UIColor {
        color(light: .white, dark: .grey9)
    }
}
