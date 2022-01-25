//
//  RecordDetailInfo.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/24.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

struct RecordItem: Codable {
    let beginTime: Date
    let endTime: Date
    let videoURL: URL
}

struct RecordDetailInfo: Codable {
    let title: String
    let ownerUUID: String
    let recordInfo: [RecordItem]
    let region: Region
    let roomType: ClassRoomType
    let rtmToken: String
    let whiteboardRoomToken: String
    let whiteboardRoomUUID: String
}
