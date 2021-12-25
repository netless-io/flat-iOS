//
//  MemberRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import Kingfisher

/// Raw type from server
struct RoomUserInfo: Decodable, Hashable {
    let name: String
    let rtcUID: UInt
    let avatarURL: URL?
}

struct MemberResponse: Decodable {
    let response: [String: RoomUserInfo]
    
    init(from decoder: Decoder) throws {
        let info = decoder.userInfo
        guard let ids = info[.init(rawValue: "ids")!] as? [String] else { throw "decode error" }
         let members = try ids.map { id -> (String, RoomUserInfo) in
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
             return (id, try container.decode(RoomUserInfo.self, forKey: .init(stringValue: id)!))
        }
        response = .init(uniqueKeysWithValues: members)
    }
}

struct MemberRequest: FlatRequest, Encodable {
    enum CodingKeys: String, CodingKey {
        case roomUUID
        case usersUUID
    }
    
    let roomUUID: String
    let usersUUID: [String]
    
    var path: String { "/v1/room/info/users" }
    let responseType = MemberResponse.self
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [.init(rawValue: "ids")!: usersUUID]
        return decoder
    }
}
