//
//  RoomUuidTest.swift
//  Flat_Test
//
//  Created by xuyunshi on 2024/1/25.
//  Copyright © 2024 agora.io. All rights reserved.
//

import XCTest
import Foundation

final class RoomUuidTest: XCTestCase {
    func testEmpty() {
        XCTAssert("".getRoomUuidFromLink() == nil)
    }
    
    func testLink() {
        let id = "17197550784"
        let link = "\(Env().webBaseURL)/join/\(id)"
        XCTAssert(link.getRoomUuidFromLink() == id)
    }
    
    func testRawUuid() {
        let uuid = "CN-2d7824a1-250b-4eda-a930-9259240444b3/a336258f-af1a-4a61-b2d5-5cb9e6d28a56"
        XCTAssert(uuid.getRoomUuidFromLink() == nil)
    }
    
    func testWhitespaceNumber() {
        let number = "  100 200 300  "
        XCTAssert(number.ignoreWhiteSpace() == "100200300")
    }
    
    func testTableSpace() {
        let number = "\t100 200 300"
        XCTAssert(number.ignoreWhiteSpace() == "100200300")
    }
    
    func testCustomScheme() {
        let str = "x-agora-flat-client://joinRoom?roomUUID=17197550784"
        XCTAssert(str.getRoomUuidFromLink() == "17197550784")
    }
    
    func testFromLongContext() {
        let str = """
135 邀请你加入 Flat 个人房间

房间主题：1111
开始时间：2024-01-25 17:41~18:41

房间号：1719 755 0784
加入链接：\(Env().webBaseURL)/join/17197550784
"""
        XCTAssert(str.getRoomUuidFromLink() == "17197550784")
    }
}
