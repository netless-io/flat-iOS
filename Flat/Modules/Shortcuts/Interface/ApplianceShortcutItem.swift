//
//  CustomShortCutItem.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

struct ApplianceShortcutItem {
    let key: String
    let title: WhiteApplianceNameKey
    let identifier: WhiteApplianceNameKey
}

let defaultApplianceKeys = [
    ApplianceShortcutItem(
        key: "s",
        title: WhiteApplianceNameKey.ApplianceSelector,
        identifier: WhiteApplianceNameKey.ApplianceSelector
    ),
    ApplianceShortcutItem(
        key: "p",
        title: WhiteApplianceNameKey.AppliancePencil,
        identifier: WhiteApplianceNameKey.AppliancePencil
    ),
    ApplianceShortcutItem(
        key: "e",
        title: WhiteApplianceNameKey.ApplianceEraser,
        identifier: WhiteApplianceNameKey.AppliancePencilEraser
    ),
    ApplianceShortcutItem(
        key: "c",
        title: WhiteApplianceNameKey.ApplianceEllipse,
        identifier: WhiteApplianceNameKey.ApplianceEllipse
    ),
    ApplianceShortcutItem(
        key: "r",
        title: WhiteApplianceNameKey.ApplianceRectangle,
        identifier: WhiteApplianceNameKey.ApplianceRectangle
    ),
    ApplianceShortcutItem(
        key: "a",
        title: WhiteApplianceNameKey.ApplianceArrow,
        identifier: WhiteApplianceNameKey.ApplianceArrow
    ),
    ApplianceShortcutItem(
        key: "l",
        title: WhiteApplianceNameKey.ApplianceStraight,
        identifier: WhiteApplianceNameKey.ApplianceStraight
    ),
    ApplianceShortcutItem(
        key: "h",
        title: WhiteApplianceNameKey.ApplianceClicker,
        identifier: WhiteApplianceNameKey.ApplianceClicker
    ),
    ApplianceShortcutItem(
        key: "t",
        title: WhiteApplianceNameKey.ApplianceText,
        identifier: WhiteApplianceNameKey.ApplianceText
    ),
]
