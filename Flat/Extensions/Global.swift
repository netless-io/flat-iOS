//
//  Global.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/30.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

let commonBorderWidth = 1 / UIScreen.main.scale

func supportApplePencil() -> Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}
