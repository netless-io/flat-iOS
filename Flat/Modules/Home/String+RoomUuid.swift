//
//  String+RoomUuid.swift
//  Flat
//
//  Created by xuyunshi on 2024/1/25.
//  Copyright © 2024 agora.io. All rights reserved.
//

import Foundation

extension String {
    func getRoomUuid() -> String? {
        if isEmpty { return nil }
        // Get link from long context.
        if let link = try? matchExpressionPattern("https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]") {
            // Get from http link.
            if let url = URL(string: link) {
                if Env().webBaseURL.contains(url.host ?? "") && url.pathComponents.contains("join") {
                    return url.lastPathComponent
                }
            }
        }
        if let link = try? matchExpressionPattern("x-agora-flat-client://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]") {
            if let url = URL(string: link), url.host == "joinRoom" {
                if let roomId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "roomUUID" })?
                    .value {
                    return roomId
                }
            }
        }
        // Get from raw uuid and replacing white space.
        return filter { !$0.isWhitespace }
    }
}
