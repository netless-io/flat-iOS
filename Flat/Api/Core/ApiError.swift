//
//  ApiError.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum ApiError: LocalizedError {
    case unknown
    case serverError(message: String)
    case message(message: String)
    case encode(message: String)
    case decode(message: String)

    var errorDescription: String? {
        switch self {
        case let .serverError(message):
            if let data = message.data(using: .utf8) {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] {
                    if let code = json["code"] as? Int {
                        return "code: \(code)"
                    }
                }
            }
            return message
        case let .message(message):
            return message
        case .unknown:
            return localizeStrings("Unknown error")
        case let .encode(message):
            return localizeStrings("Encode error") + " " + message
        case let .decode(message):
            if message.isEmpty { return localizeStrings("Decode error") }
            return message
        }
    }
}
