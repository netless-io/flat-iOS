//
//  JSONDecoder+AnyKeyDecodable.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

extension JSONDecoder {
    func setAnyCodingKey(_ key: String) {
        userInfo[anyCodingKeyIdentifier] = AnyCodingKey(stringValue: key)!
    }
}
