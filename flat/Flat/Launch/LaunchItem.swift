//
//  LaunchParse.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol LaunchItem {
    var afterLoginImplementation: ((LaunchCoordinator)->Void)? { get }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator)
    
    func shouldHandle(url: URL) -> Bool
}
