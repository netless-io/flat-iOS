//
//  NetlessResponseHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

class NetlessResponseHandler: ResponseDataHandler {
    func processResponseData<T>(_ data: Data, decoder: JSONDecoder, forResponseType: T.Type) throws -> T where T : Decodable {
        try decoder.decode(T.self, from: data)
    }
}
