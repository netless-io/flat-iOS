//
//  WhiteBoardOperation.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Whiteboard

struct WhiteboardPanelConfig {
    static var defaultColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen,
                                           .systemTeal, .systemBlue, .init(hexString: "#6236FF"), .systemPurple,
                                           .init(hexString: "#BCC0C6"), .systemGray, .black, .white]
    
    static var defaultCompactPanelItems: [[WhitePanelItem]] {
        return [[
            .single(.removeSelection),
            .color(displayColor: defaultColors.first!),
            .subOps(ops: [
                .appliance(.ApplianceArrow),
                .appliance(.ApplianceSelector),
                .appliance(.AppliancePencil),
                .appliance(.ApplianceRectangle),
                .appliance(.ApplianceText),
                .appliance(.ApplianceEraser),
                .clean
            ], current: .appliance(.ApplianceArrow))
        ]]
    }
    
    static var defaultPanelItems: [[WhitePanelItem]] {
        return [
            [.single(.removeSelection)],
            [.single(.appliance(.ApplianceClicker)),
                .single(.appliance(.ApplianceSelector)),
                .single(.appliance(.AppliancePencil)),
                .single(.appliance(.ApplianceText)),
                .single(.appliance(.ApplianceEraser)),
            .subOps(ops: [.appliance(.ApplianceRectangle),
                          .appliance(.ApplianceEllipse),
                          .appliance(.ApplianceArrow),
                          .appliance(.ApplianceStraight)], current: .appliance(.ApplianceRectangle)),
            .color(displayColor: defaultColors.first!),
            .single(.clean)
        ]]
    }
}

enum WhiteboardPanelOperation: Equatable {
    case appliance(WhiteApplianceNameKey)
    case clean
    case removeSelection
    
    // execute
    func execute(inRoom room: WhiteRoom) {
        switch self {
        case .appliance(let whiteApplianceNameKey):
            let newState = WhiteMemberState()
            newState.currentApplianceName = whiteApplianceNameKey
            room.setMemberState(newState)
        case .clean:
            room.cleanScene(true)
        case .removeSelection:
            room.deleteOperation()
        }
    }
    
    var selectable: Bool {
        if case .appliance = self {
            return true
        }
        return false
    }
    
    var onlyAction: Bool {
        switch self {
        case .appliance:
            return false
        case .clean:
            return true
        case .removeSelection:
            return true
        }
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
        case .removeSelection: return UIImage(named: "whiteboard_remove_selection")!
        }
    }
        
    var image: UIImage {
        switch self {
        case .appliance:
            return rawImage.tintColor(.controlNormal)
        case .removeSelection:
            return rawImage.tintColor(.systemRed)
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
        case .clean, .removeSelection:
            return image
        }
    }
}

enum WhitePanelItem: Equatable {
    case single(WhiteboardPanelOperation)
    case subOps(ops: [WhiteboardPanelOperation], current: WhiteboardPanelOperation?)
    case color(displayColor: UIColor)
    
    static func == (lhs: WhitePanelItem, rhs: WhitePanelItem) -> Bool {
        switch (lhs, rhs) {
        case (.single(let l), .single(let r)):
            return l == r
        case (.subOps(ops: let ls, _), .subOps(ops: let rs, _)):
            return ls == rs
        case (.color, .color):
            return true
        default:
            return false
        }
    }
    
    func contains(operation: WhiteboardPanelOperation) -> Bool {
        switch self {
        case .single(let whiteboardPanelOperation):
            return whiteboardPanelOperation == operation
        case .subOps(let ops, _):
            return ops.contains(operation)
        case .color:
            // Color won't be contained in any operations
            return false
        }
    }
    
    var appliance: WhiteApplianceNameKey? {
        switch self {
        case .single(let op):
            return op.appliance
        case .subOps(_, current: let current):
            return current?.appliance
        case .color:
            return nil
        }
    }
    
    var hasSubMenu: Bool {
        switch self {
        case .subOps: return true
        case .color: return true
        default: return false
        }
    }
    
    var selectable: Bool {
        switch self {
        case .single(let whiteboardPanelOperation):
            return whiteboardPanelOperation.selectable
        case .subOps(let ops, _):
            // 不重要：不是看 current 么？
            switch ops[0] {
            case .appliance: return true
            default: return false
            }
        case .color:
            return false
        }
    }
    
    var onlyAction: Bool {
        switch self {
        case .single(let whiteboardPanelOperation):
            return whiteboardPanelOperation.onlyAction
        case .subOps:
            return false
        case .color:
            return false
        }
    }
    
    var image: UIImage {
        switch self {
        case .single(let whiteboardPanelOperation):
            return whiteboardPanelOperation.image
        case .subOps(let ops, let current):
            return current?.image ?? ops.first!.image
        case .color(let color):
            return UIImage.pickerItemImage(withColor: color, size: .init(width: 18, height: 18), radius: 9)!
        }
    }
    
    var selectedImage: UIImage {
        switch self {
        case .single(let whiteboardPanelOperation):
            return whiteboardPanelOperation.selectedImage
        case .subOps(let ops, let current):
            return current?.selectedImage ?? ops.first!.selectedImage
        case .color:
            let bg = UIImage.pointWith(color: .controlSelectedBG,
                              size: .init(width: 30, height: 30),
                              radius: 5)
            let selected = bg.compose(image)!
            return selected
        }
    }
}
