//
//  AnyDecodable.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

let anyCodingKeyIdentifier = CodingUserInfoKey(rawValue: "anyCodingKey")!

/// decode any key from data without declare a file
/// you should declare a identifier in decode
/// such as '
///  decoder.userInfo = [
///  anyCodingKeyIdentifier: AnyCodingKey(stringValue: "location")!]
///  '
/// then you can use it as
///  ' decode.decode(AnyDecodable<String>.self, from data) '
///  or
///  ' decode.decode(AnyDecodable<Int>.self, from data) '
struct AnyKeyDecodable<T: Decodable>: Decodable {
    let result: T
    
    init(from decoder: Decoder) throws {
        guard let key = decoder.userInfo[anyCodingKeyIdentifier] as? AnyCodingKey else {
            throw "anyCodingKey does not exist"
        }
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let result = try container.decode(T.self, forKey: key)
        self.result = result
    }
}
