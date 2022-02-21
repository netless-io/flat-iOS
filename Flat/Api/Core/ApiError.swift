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
        case .serverError(let message):
            if let data = message.data(using: .utf8) {
                if let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] {
                    if let code = json["code"] as? Int {
                        return "code: \(code)"
                    }
                }
            }
            return message
        case .message(let message):
            return message
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        case .encode(let message):
            return NSLocalizedString("Encode error", comment: "") + " " + message
        case .decode(let message):
            return NSLocalizedString("Decode error", comment: "") + " " + message
        }
    }
}
