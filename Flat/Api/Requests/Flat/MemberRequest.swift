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
    // Empty sometimes. Do not use URL type
    let avatarURL: String

    func toRoomUser(uid: String, isOnline: Bool) -> RoomUser {
        .init(rtmUUID: uid,
              rtcUID: rtcUID,
              name: name,
              avatarURL: URL(string: avatarURL),
              isOnline: isOnline)
    }
}

struct MemberResponse: Decodable {
    let response: [String: RoomUserInfo]

    init(from decoder: Decoder) throws {
        if let ids = decoder.userInfo[.init(rawValue: "ids")!] as? [String] {
            let members = try ids.map { id -> (String, RoomUserInfo) in
                let container = try decoder.container(keyedBy: AnyCodingKey.self)
                return (id, try container.decode(RoomUserInfo.self, forKey: .init(stringValue: id)!))
            }
            response = .init(uniqueKeysWithValues: members)
            return
        }

        response = try decoder.singleValueContainer().decode([String: RoomUserInfo].self)
    }
}

struct MemberRequest: FlatRequest, Encodable {
    enum CodingKeys: String, CodingKey {
        case roomUUID
        case usersUUID
    }

    let roomUUID: String
    let usersUUID: [String]?

    var path: String { "/v1/room/info/users" }
    let responseType = MemberResponse.self

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        if let usersUUID {
            decoder.userInfo = [.init(rawValue: "ids")!: usersUUID]
        }
        return decoder
    }
}
