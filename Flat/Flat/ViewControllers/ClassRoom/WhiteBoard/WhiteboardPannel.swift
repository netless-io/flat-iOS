//
//  WhiteboardPannel.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

struct WhiteboardPannel {
    static var operations: [WhiteBoardOperation] = [
        .updateAppliance(name: .ApplianceClicker),
        .updateAppliance(name: .ApplianceSelector),
        .updateAppliance(name: .AppliancePencil),
        .updateAppliance(name: .ApplianceRectangle),
        .updateAppliance(name: .ApplianceEllipse),
        .updateAppliance(name: .ApplianceText),
        .updateAppliance(name: .ApplianceEraser),
        .updateAppliance(name: .ApplianceArrow),
        .updateAppliance(name: .ApplianceStraight),
        .clean
    ]
}
