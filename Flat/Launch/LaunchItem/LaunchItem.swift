//
//  LaunchParse.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

// An Item can be registered to Application launch process
protocol LaunchItem {
    // The task should be executed after user login
    func afterLoginSuccessImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator, user: User)

    // The Task will be immediately execute when the item been handle
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator)

    func shouldHandle(url: URL?, scene: UIScene) -> Bool

    func shouldHandle(userActivity: NSUserActivity, scene: UIScene) -> Bool
}
