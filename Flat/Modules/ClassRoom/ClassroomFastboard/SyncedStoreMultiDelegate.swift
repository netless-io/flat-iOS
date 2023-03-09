//
//  SyncedStoreMultiDelegate.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/8.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

class SyncedStoreMultiDelegate: NSObject, SyncedStoreUpdateCallBackDelegate {
    var items: NSHashTable<SyncedStoreUpdateCallBackDelegate> = .init()
    func syncedStoreDidUpdateStoreName(_ name: String, partialValue: [AnyHashable : Any]) {
        items.allObjects.forEach {
            $0.syncedStoreDidUpdateStoreName(name, partialValue: partialValue)
        }
    }
}
