//
//  FlatResponseDataHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

class FlatResponseHandler: ResponseDataHandler {
    func processResponseData<T>(_ data: Data, decoder: JSONDecoder, forResponseType: T.Type) throws -> T where T : Decodable {
        guard let jsonObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
              let status = jsonObj["status"] as? Int else {
            throw ApiError.serverError(message: "unknown data type")
        }
        // JWT Fail
        if let code = jsonObj["code"] as? Int, code == 100006 {
            DispatchQueue.main.async {
                AuthStore.shared.logout()
            }
            throw ApiError.message(message: "JWT expire")
        }
        guard status == 0 else {
            let str = String(data: data, encoding: .utf8)
            throw ApiError.serverError(message: str ?? "")
        }
        decoder.setAnyCodingKey("data")
        return (try decoder.decode(AnyKeyDecodable<T>.self, from: data)).result
    }
}
