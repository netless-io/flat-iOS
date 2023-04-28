//
//  GlobalKeyboardShortcutRespondable.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

@objc
protocol GlobalKeyboardShortcutRespondable: AnyObject {
    /// Mapped to Command-N
    @objc
    optional func createNewItem(_: Any?)

    @objc
    optional func escape(_: Any?)
}
