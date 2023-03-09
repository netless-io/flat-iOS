//
//  VideoLayoutStore.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/7.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

protocol VideoLayoutStore {
    func layoutState() -> Observable<VideoLayoutState>
    func updateExpandUsers(_ usersUUID: [String])
    func removeFreeDraggingUsers(_ users: [String])
    func updateFreeDraggingUsers(_ users: [DraggingUser])
}

struct DraggingUser {
    let uuid: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    var z: Int

    init(
        uuid: String,
        x: CGFloat,
        y: CGFloat,
        z: Int,
        width: CGFloat,
        height: CGFloat
    ) {
        self.uuid = uuid
        self.x = x
        self.y = y
        self.z = z
        self.width = width
        self.height = height
    }

    init?(uuid: String, dictionary: NSDictionary) {
        guard
            let x = (dictionary.value(forKey: "x") as? NSNumber)?.floatValue,
            let y = (dictionary.value(forKey: "y") as? NSNumber)?.floatValue,
            let z = (dictionary.value(forKey: "z") as? NSNumber)?.intValue,
            let width = (dictionary.value(forKey: "width") as? NSNumber)?.floatValue,
            let height = (dictionary.value(forKey: "height") as? NSNumber)?.floatValue
        else { return nil }
        self.x = CGFloat(x)
        self.y = CGFloat(y)
        self.z = z
        self.width = CGFloat(width)
        self.height = CGFloat(height)
        self.uuid = uuid
    }

    func valueDic() -> [String: Any] {
        [
            "x": x,
            "y": y,
            "z": z,
            "width": width,
            "height": height
        ]
    }
}

struct VideoLayoutState {
    let gridUsers: [String]
    let freeDraggingUsers: [DraggingUser]
}
