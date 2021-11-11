//
//  ApiError.swift
//  flat
//
//  Created by xuyunshi on 2021/10/12.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

enum ApiError: Error {
    case unknown
    case serverError(message: String)
    case message(message: String)
    case encode(message: String)
    case decode(message: String)
    
    var localizedDescription: String {
        switch self {
        case .serverError(let message):
            return "server error \(message)"
        case .message(let message):
            return message
        case .unknown:
            return "unknown error"
        case .encode(let message):
            return "encode error \(message)"
        case .decode(let message):
            return "decode error \(message)"
        }
    }
}
