//
//  RoomInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import RxSwift

struct RawRoomInfo: Decodable {
    let roomInfo: RoomInfo
}

struct RoomInfo: Decodable {
    let title: String
    let beginTime: Date
    let endTime: Date
    let roomType: ClassRoomType
    var roomStatus: RoomStartStatus
    let hasRecord: Bool
    let ownerUUID: String
    let ownerUserName: String
    let region: String
    let inviteCode: String
    
    var formatterInviteCode: String {
        inviteCode.split(every: 3).joined(separator: " ")
    }
}

extension RoomInfo {
    static func fetchInfoBy(uuid: String) -> Observable<Self> {
        let request = RoomInfoRequest(uuid: uuid)
        return ApiProvider.shared.request(fromApi: request).map { $0.roomInfo }
    }
    
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
