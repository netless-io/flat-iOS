//
//  RegexTest.swift
//  Flat_Test
//
//  Created by xuyunshi on 2023/11/3.
//  Copyright © 2023 agora.io. All rights reserved.
//

import XCTest

final class RegexTest: XCTestCase {
    func testJoinRoomMatch() {
        let str = "1027 733 5074"
        let num = try? str.matchExpressionPattern("[\\d\\s]+\\d$")
        print(num)
        
        let str1 = "1027 733 507"
        let num1 = try? str1.matchExpressionPattern("[\\d\\s]+\\d$")
        print(num1)
        
        let str2 = "1027733507"
        let num2 = try? str2.matchExpressionPattern("[\\d\\s]+\\d$")
        print(num2)
    }
}
