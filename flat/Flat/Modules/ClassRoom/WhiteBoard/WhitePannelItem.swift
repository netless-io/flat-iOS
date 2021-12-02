//
//  WhiteBoardOperation.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard

struct WhiteboardPannelConfig {
    static var defaultColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen,
                                           .systemTeal, .systemBlue, .init(hexString: "#6236FF"), .systemPurple,
                                           .init(hexString: "#BCC0C6"), .systemGray, .black, .white]
    
    static var defaultPannelItems: [WhitePannelItem] {
        return [
            .single(.appliance(.ApplianceClicker)),
                .single(.appliance(.ApplianceSelector)),
                .single(.appliance(.AppliancePencil)),
                .single(.appliance(.ApplianceText)),
                .single(.appliance(.ApplianceEraser)),
            .subops(ops: [.appliance(.ApplianceRectangle),
                          .appliance(.ApplianceEllipse),
                          .appliance(.ApplianceArrow),
                          .appliance(.ApplianceStraight)], current: .appliance(.ApplianceRectangle)),
            .colorAndWidth(displayColor: defaultColors.first!),
            .single(.clean)
        ]
    }
}

enum WhiteboardPannelOperation: Equatable {
    case appliance(WhiteApplianceNameKey)
    case clean
    
    func excute(inRoom room: WhiteRoom) {
        switch self {
        case .appliance(let whiteApplianceNameKey):
            let newState = WhiteMemberState()
            newState.currentApplianceName = whiteApplianceNameKey
            room.setMemberState(newState)
        case .clean:
            room.cleanScene(true)
        }
    }
    
    var selectable: Bool {
        if case .appliance = self {
            return true
        }
        return false
    }
    
    var onlyAction: Bool {
        if case .clean = self { return true }
        return false
    }
    
    var appliance: WhiteApplianceNameKey? {
        switch self {
        case .appliance(let whiteApplianceNameKey):
            return whiteApplianceNameKey
        default:
            return nil
        }
    }
    
    private var rawImage: UIImage {
        switch self {
        case .appliance(name: let name):
            return .init(appliance: name)!
        case .clean: return UIImage(named: "whiteboard_clean")!
        }
    }
        
    var image: UIImage {
        switch self {
        case .appliance:
            return rawImage.tintColor(.controlNormal)
        case .clean:
            return rawImage.tintColor(.controlNormal)
        }
    }
    
    var selectedImage: UIImage {
        switch self {
        case .appliance:
            return image.tintColor(.controlSelected,
                                   backgroundColor: .controlSelectedBG,
                                   cornerRadius: 5)
        case .clean:
            return image
        }
    }
}

enum WhitePannelItem: Equatable {
    case single(WhiteboardPannelOperation)
    case subops(ops: [WhiteboardPannelOperation], current: WhiteboardPannelOperation?)
    case colorAndWidth(displayColor: UIColor)
    
    static func == (lhs: WhitePannelItem, rhs: WhitePannelItem) -> Bool {
        switch (lhs, rhs) {
        case (.single(let l), .single(let r)):
            return l == r
        case (.subops(ops: let ls, _), .subops(ops: let rs, _)):
            return ls == rs
        case (.colorAndWidth, .colorAndWidth):
            return true
        default:
            return false
        }
    }
    
    func contains(operation: WhiteboardPannelOperation) -> Bool {
        switch self {
        case .single(let whiteboardPannelOperation):
            return whiteboardPannelOperation == operation
        case .subops(let ops, _):
            return ops.contains(operation)
        case .colorAndWidth:
            return false
        }
    }
    
    var appliance: WhiteApplianceNameKey? {
        switch self {
        case .single(let op):
            return op.appliance
        case .subops(_, current: let current):
            return current?.appliance
        case .colorAndWidth:
            return nil
        }
    }
    
    var hasSubMenu: Bool {
        switch self {
        case .subops: return true
        case .colorAndWidth: return true
        default: return false
        }
    }
    
    var selectable: Bool {
        switch self {
        case .single(let whiteboardPannelOperation):
            return whiteboardPannelOperation.selectable
        case .subops(let ops, _):
            switch ops[0] {
            case .appliance: return true
            default: return false
            }
        case .colorAndWidth:
            return false
        }
    }
    
    var onlyAction: Bool {
        switch self {
        case .single(let whiteboardPannelOperation):
            return whiteboardPannelOperation.onlyAction
        case .subops:
            return false
        case .colorAndWidth:
            return false
        }
    }
    
    var image: UIImage {
        switch self {
        case .single(let whiteboardPannelOperation):
            return whiteboardPannelOperation.image
        case .subops(let ops, let current):
            return current?.image ?? ops.first!.image
        case .colorAndWidth(let color):
            return UIImage.pickerItemImage(withColor: color, size: .init(width: 18, height: 18), radius: 9)!
        }
    }
    
    var selectedImage: UIImage {
        switch self {
        case .single(let whiteboardPannelOperation):
            return whiteboardPannelOperation.selectedImage
        case .subops(let ops, let current):
            return current?.selectedImage ?? ops.first!.selectedImage
        case .colorAndWidth:
            let bg = UIImage.pointWith(color: .controlSelectedBG,
                              size: .init(width: 30, height: 30),
                              radius: 5)
            let selected = bg.compose(image)!
            return selected
        }
    }
}
