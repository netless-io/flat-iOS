//
//  CreateRoomRequest.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct CreateRoomRequest: FlatRequest, Encodable {
    enum CodingKeys: String, CodingKey {
        case beginTime
        case region
        case title
        case type
    }

    let beginTime: Date
    let region: FlatRegion
    let title: String
    let type: ClassRoomType

    var path: String { "/v1/room/create/ordinary" }
    let responseType = JoinRoomInfo.self
}
