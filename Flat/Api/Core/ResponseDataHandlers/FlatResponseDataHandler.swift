//
//  FlatResponseDataHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

class FlatResponseHandler: ResponseDataHandler {
    static var jwtExpireSignal = PublishRelay<Void>()

    func processResponseData<T>(_ data: Data, decoder: JSONDecoder, forResponseType _: T.Type) throws -> T where T: Decodable {
        guard let jsonObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
              let status = jsonObj["status"] as? Int
        else {
            throw ApiError.serverError(message: "unknown data type")
        }

        if let code = jsonObj["code"] as? Int,
           let error = FlatApiError(rawValue: code)
        {
            if error == .JWTSignFailed {
                FlatResponseHandler.jwtExpireSignal.accept(())
            }
            throw ApiError.message(message: error.localizedDescription)
        }
        guard status == 0 else {
            let str = String(data: data, encoding: .utf8)
            throw ApiError.serverError(message: str ?? "")
        }
        decoder.setAnyCodingKey("data")
        return (try decoder.decode(AnyKeyDecodable<T>.self, from: data)).result
    }
}
