//
//  RoomInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct RawRoomInfo: Decodable {
    let roomInfo: RoomInfo
}

struct RoomInfo: Decodable {
    let title: String
    let beginTime: Date
    let endTime: Date
    let roomType: ClassRoomType
    let roomStatus: RoomStartStatus
    let hasRecord: Bool
    let ownerUUID: String
    let ownerUserName: String
    let region: String
    let inviteCode: String
}

extension RoomInfo {
    static func fetchInfoBy(uuid: String, completion: @escaping ((Result<Self, ApiError>)->Void)) {
        let request = RoomInfoRequest(uuid: uuid)
        ApiProvider.shared.request(fromApi: request) { result in
            switch result {
            case .success(let raw):
                completion(.success(raw.roomInfo))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
