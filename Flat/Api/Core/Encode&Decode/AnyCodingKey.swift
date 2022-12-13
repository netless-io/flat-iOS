//
//  AnyCodingKey.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct AnyCodingKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.intValue = intValue
        stringValue = intValue.description
    }
}
