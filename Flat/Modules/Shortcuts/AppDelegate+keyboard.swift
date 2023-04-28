//
//  AppDelegate+keyboard.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Whiteboard

extension AppDelegate {
    // MARK: - Keyboard

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        let esc = UIKeyCommand(action: #selector(GlobalKeyboardShortcutRespondable.escape), input: UIKeyCommand.inputEscape)
        esc.title = localizeStrings("Escape")

        let deleteCommand = UIKeyCommand(
            title: localizeStrings("DeleteWhiteSelectedItem"),
            action: #selector(ClassroomKeyboardRespondable.deleteSelectedItem),
            input: "\u{8}" // This is the backspace character represented as a Unicode scalar
        )

        let cleanCommand = UIKeyCommand(
            title: localizeStrings("ClearWhiteboard"),
            action: #selector(ClassroomKeyboardRespondable.clearWhiteboard),
            input: "k",
            modifierFlags: .command
        )

        builder.replaceChildren(ofMenu: .standardEdit) { children in
            [esc, deleteCommand, cleanCommand] + children
        }
        
        var keyboardCommands = defaultApplianceKeys.map {
            UIKeyCommand(
                title: localizeStrings("appliance." + $0.identifier.rawValue),
                action: #selector(ClassroomKeyboardRespondable.updateAppliance(_:)),
                input: $0.key,
                propertyList: [$0.identifier.rawValue]
            )
        }

        let nextColor = UIKeyCommand(
            title: localizeStrings("SwitchNextColor"),
            action: #selector(ClassroomKeyboardRespondable.switchNextColor(_:)),
            input: "c",
            modifierFlags: .alternate
        )

        let preColor = UIKeyCommand(
            title: localizeStrings("SwitchPrevColor"),
            action: #selector(ClassroomKeyboardRespondable.switchPrevColor(_:)),
            input: "c",
            modifierFlags: [.shift, .alternate]
        )
        keyboardCommands.append(nextColor)
        keyboardCommands.append(preColor)

        let appliance = UIMenu(title: localizeStrings("ApplianceMenu"), children: keyboardCommands)
        builder.insertSibling(appliance, afterMenu: .view)

        let pageMenu = UIMenu(title: localizeStrings("PageMenu"), children: [
            UIKeyCommand(
                title: localizeStrings("PageNext"),
                action: #selector(ClassroomKeyboardRespondable.nextPage(_:)),
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: [.command, .alternate]
            ),
            UIKeyCommand(
                title: localizeStrings("PagePrev"),
                action: #selector(ClassroomKeyboardRespondable.prevPage(_:)),
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: [.command, .alternate]
            ),
            UIKeyCommand(
                title: localizeStrings("NewPage"),
                action: #selector(GlobalKeyboardShortcutRespondable.createNewItem),
                input: "n",
                modifierFlags: .command
            ),
        ])
        builder.insertSibling(pageMenu, afterMenu: appliance.identifier)
    }
}
