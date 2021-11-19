//
//  WhiteBoardOperation.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard

enum WhiteBoardOperation {
    case updateAppliance(name: WhiteApplianceNameKey)
    case clean
}

extension WhiteBoardOperation {
    var buttonImage: UIImage? {
        switch self {
        case .clean:
            return UIImage(named: "whiteboard_clean")
        case .updateAppliance(name: let name):
            return .init(appliance: name)
        }
    }
}
