//
//  AgoraResponseDataHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

class AgoraResponseHandler: ResponseDataHandler {
    func processResponseData<T>(_ data: Data, decoder: JSONDecoder, forResponseType: T.Type) throws -> T where T : Decodable {
        guard let jsonObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
              let resultStr = jsonObj["result"] as? String,
              resultStr == "success" else {
                  let str = String(data: data, encoding: .utf8)
                  throw ApiError.serverError(message: str ?? "")
              }
        return try decoder.decode(T.self, from: data)
    }
}
