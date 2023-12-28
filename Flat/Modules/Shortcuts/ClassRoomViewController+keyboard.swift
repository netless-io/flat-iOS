//
//  ClassRoomViewController+keyboard.swift
//  Flat
//
//  Created by xuyunshi on 2023/4/27.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Fastboard
import UIKit

extension ClassRoomViewController: GlobalKeyboardShortcutRespondable {
    func escape(_: Any?) {
        if presentedViewController != nil {
            dismiss(animated: true)
            return
        }
        if fastboardViewController.roomPermission.value.inputEnable {
            fastboardViewController.fastRoom.dismissAllSubPanels()
            // Update appliance to update focus.
            if let i = fastboardViewController.fastRoom.room?.memberState.currentApplianceName.rawValue {
                fastboardViewController.fastRoom.updateApplianceIdentifier(i)
            }
        }
    }
}

extension ClassRoomViewController: ClassroomKeyboardRespondable {
    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { true }
    
    override func validate(_ command: UICommand) {
        if #available(iOS 14.0, *) {
            if ProcessInfo().isiOSAppOnMac {
                if command.action == #selector(ClassroomKeyboardRespondable.updateAppliance(_:)) {
                    command.attributes = .hidden
                }
            }
        }
        super.validate(command)
    }
    
    func clearWhiteboard(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.cleanScene(false)
    }
    
    func nextPage(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.nextPage()
    }
    
    func prevPage(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.prevPage()
    }
    
    func updateAppliance(_ item: Any?) {
        guard
            let command = item as? UIKeyCommand,
            let identifier = (command.propertyList as? [String])?.first as? String,
            fastboardViewController.roomPermission.value.inputEnable,
            fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.updateApplianceIdentifier(identifier)
    }
    
    func switchNextColor(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        if let color = fastboardViewController.fastRoom.nextColor() {
            let i = UIImageView(image: UIImage.pointWith(color: color, size: .init(width: 44, height: 44), radius: 22))
            toast(i)
        }
    }
    
    func switchPrevColor(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        if let color = fastboardViewController.fastRoom.prevColor() {
            let i = UIImageView(image: UIImage.pointWith(color: color, size: .init(width: 44, height: 44), radius: 22))
            toast(i)
        }
    }
    
    func createNewItem(_: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.addPage()
        fastboardViewController.fastRoom.room?.nextPage()
    }
    
    func deleteSelectedItem(_: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.deleteOperation()
    }
    
    // MARK: - Standard Edit Actions

    @objc
    func undo(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.undo()
    }
    
    @objc
    func redo(_ item: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.redo()
    }
    
    override func copy(_ sender: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.copy()
    }
    
    override func paste(_ sender: Any?) {
        guard fastboardViewController.roomPermission.value.inputEnable, fastboardViewController.isRoomJoined.value else { return }
        fastboardViewController.fastRoom.room?.paste()
    }
}
