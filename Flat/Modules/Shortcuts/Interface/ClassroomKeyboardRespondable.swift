//
//  ClassroomKeyboardRespondable.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

@objc
protocol ClassroomKeyboardRespondable: AnyObject {
    @objc
    optional func deleteSelectedItem(_ item: Any?)
    
    @objc
    optional func clearWhiteboard(_ item: Any?)
    
    @objc
    optional func updateAppliance(_ item: Any?)
    
    @objc
    optional func switchNextColor(_ item: Any?)
    
    @objc
    optional func switchPrevColor(_ item: Any?)
    
    @objc
    optional func prevPage(_ item: Any?)
    
    @objc
    optional func nextPage(_ item: Any?)
}
