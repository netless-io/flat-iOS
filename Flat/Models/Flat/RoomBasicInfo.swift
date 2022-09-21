//
//  RoomListInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import RxSwift
import Fastboard

/// Get from list or by 'ordinary' request
struct RoomBasicInfo: Decodable, Equatable {
    let roomUUID: String
    let periodicUUID: String?
    
    let ownerUUID: String
    let ownerName: String
    var isOwner: Bool {
        ownerUUID == AuthStore.shared.user?.userUUID ?? ""
    }
    
    let title: String
    let roomType: ClassRoomType
    let beginTime: Date
    let endTime: Date
    var roomStatus: RoomStartStatus
    
    let region: String
    let hasRecord: Bool
    let inviteCode: String
    let ownerAvatarURL: String
    
    var formatterInviteCode: String {
        inviteCode.split(every: 3).joined(separator: " ")
    }
}

extension RoomBasicInfo {
    /// This method can't get periodicUUID
    /// Periodic room info can be fetched either periodicUUID or a inviteUUID
    static func fetchInfoBy(uuid: String, periodicUUID: String?) -> Observable<Self> {
        let request = RoomInfoRequest(uuid: uuid)
        return ApiProvider.shared.request(fromApi: request).map {
            let info = $0.roomInfo
            return RoomBasicInfo(roomUUID: uuid,
                                 periodicUUID: periodicUUID,
                                 ownerUUID: info.ownerUUID,
                                 ownerName: info.ownerUserName,
                                 title: info.title,
                                 roomType: info.roomType,
                                 beginTime: info.beginTime,
                                 endTime: info.endTime,
                                 roomStatus: info.roomStatus,
                                 region: info.region,
                                 hasRecord: info.hasRecord,
                                 inviteCode: info.inviteCode,
                                 ownerAvatarURL: "")
        }
    }
    
    /// This method can't get periodicUUID
    /// Periodic room info can be fetched either periodicUUID or a inviteUUID
    static func fetchInfoBy(uuid: String, periodicUUID: String?, completion: @escaping ((Result<Self, ApiError>)->Void)) {
        let request = RoomInfoRequest(uuid: uuid)
        ApiProvider.shared.request(fromApi: request) { result in
            switch result {
            case .success(let raw):
                let info = raw.roomInfo
                let basicInfo = RoomBasicInfo(roomUUID: uuid,
                                              periodicUUID: periodicUUID,
                                              ownerUUID: info.ownerUUID,
                                              ownerName: info.ownerUserName,
                                              title: info.title,
                                              roomType: info.roomType,
                                              beginTime: info.beginTime,
                                              endTime: info.endTime,
                                              roomStatus: info.roomStatus,
                                              region: info.region,
                                              hasRecord: info.hasRecord,
                                              inviteCode: info.inviteCode,
                                              ownerAvatarURL: "")
                completion(.success(basicInfo))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

fileprivate struct RoomInfoRequest: FlatRequest {
    let uuid: String
    
    var path: String { "/v1/room/info/ordinary" }
    var task: Task { .requestJSONEncodable(encodable: ["roomUUID": uuid]) }
    let responseType = RawRoomInfo.self
}

// Middle Struct
fileprivate struct RawRoomInfo: Decodable {
    let roomInfo: RoomInfo
}

// Middle Struct
fileprivate struct RoomInfo: Decodable {
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
}
