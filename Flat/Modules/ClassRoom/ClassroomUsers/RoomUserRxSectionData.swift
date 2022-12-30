//
//  RoomUser+RxDatasource.swift
//  Flat
//
//  Created by xuyunshi on 2022/12/30.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxDataSources

extension RoomUser: IdentifiableType {
    var identity: String { rtmUUID }
}

struct RoomUserRxSectionData: AnimatableSectionModelType {
    // Always one section
    var identity: String = "_"
    
    var items: [RoomUser]
    
    init(items: [RoomUser]) {
        self.items = items
    }
    
    init(original: RoomUserRxSectionData, items: [RoomUser]) {
        self = original
        self.items = items
    }
}
