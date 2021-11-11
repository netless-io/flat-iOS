//
//  ResponseHandler.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol ResponseDataHandler {
    func processResponseData<T: Decodable>(_ data: Data, decoder: JSONDecoder, forResponseType: T.Type) throws -> T
}
