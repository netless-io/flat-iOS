//
//  LogSensetiveTest.swift
//  Flat_Test
//
//  Created by xuyunshi on 2023/9/25.
//  Copyright © 2023 agora.io. All rights reserved.
//

import XCTest

final class LogSensetiveTest: XCTestCase {
    func testFilter() {
        let testInput = "[Core], raw data 4EB6D755-257A-4A95-9F62-182F08519B02 {\"status\":0,\"data\":{\"name\":\"6666\",\"avatar\":\"https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/avatar/14.png\",\"userUUID\":\"ef935086-a2da-4997-92ba-89a6b31656ae\",\"token\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6ImVmOTM1MDg2LWEyZGEtNDk5NzxklcjzklxjflsdjflkL_c\",\"hasPhone\":true,\"hasPassword\":false}}"

        let expression = try! NSRegularExpression(pattern: "\"token\":\"(.*?)\"")
        let range = NSRange(testInput.startIndex..<testInput.endIndex, in: testInput)
        if let match = expression.firstMatch(in: testInput, range: range) {
            if let range = Range(match.range(at: 0), in: testInput) {
                let matchText = String(testInput[range])
                print("match string:", matchText)
            } else {
                XCTAssert(true, "test has no token")
            }
            
            if let range = Range(match.range(at: 1), in: testInput) {
                let matchText = String(testInput[range])
                print("match token:", matchText)
            } else {
                XCTAssert(true, "test has no token")
            }
        }
        
        let output = SensetiveLogFilter.filter(testInput)
        let outputRange = NSRange(output.startIndex..<output.endIndex, in: output)
        if let match = expression.firstMatch(in: output, range: outputRange) {
            guard let range = Range(match.range(at: 1), in: output) else {
                XCTAssert(false)
                return
            }
            let matchToken = String(output[range]).dropFirst().dropLast() // Drop \"
            XCTAssert(matchToken.allSatisfy({ $0 == "*" }), "token not erased")
            return
        }
        XCTAssert(false)
    }
    
    func testNormalLogFilter() {
        let testInput = "[Core], raw data 4EB6D755-257A-4A95-9F62-182F08519B02 {\"status\":0,\"data\":{\"name\":\"6666\",\"avatar\":\"https://flat-storage.oss-cn-hangzhou.aliyuncs.com/flat-resources/avatar/14.png\",\"userUUID\":\"ef935086-a2da-4997-92ba-89a6b31656ae\",\"hasPhone\":true,\"hasPassword\":false}}"
        XCTAssert(SensetiveLogFilter.filter(testInput) == testInput, "fail filter normal log")
    }
}
