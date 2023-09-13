//
//  Flat_Test.swift
//  Flat_Test
//
//  Created by xuyunshi on 2023/8/22.
//  Copyright © 2023 agora.io. All rights reserved.
//

import XCTest

final class EnvTest: XCTestCase {
    func testServers() {
        let env = Env()
        let servers = env.servers
        XCTAssert(!servers.isEmpty)

        let contiansSelf = servers.contains(where: { $0.baseURL == env.baseURL })
        XCTAssert(contiansSelf)
    }

    func testCustomDomain() {
        let env = Env()

        let cnPath: String
        let sgPath: String
        #if DEBUG
            cnPath = "flat-api-dev.whiteboard.agora.io"
            sgPath = "flat-api-dev-sg.whiteboard.agora.io"
        #else
            cnPath = "flat-api.whiteboard.agora.io"
            sgPath = "api.flat.agora.io"
        #endif

        let startRange = 0 ... 9
        // 10 num.
        for s in startRange {
            let roomUUID = s.description + String(repeating: "0", count: 9)
            guard let baseUrl = env.customBaseUrlFor(roomUUID: roomUUID) else {
                XCTAssert(false, "can't find url")
                return
            }
            XCTAssert(baseUrl.contains(cnPath), "error base url \(baseUrl)")
        }

        // 11 num start with 1.
        let cnroomUUID = "1" + String(repeating: "0", count: 10)
        guard let baseUrl = env.customBaseUrlFor(roomUUID: cnroomUUID) else {
            XCTAssert(false, "can't find url")
            return
        }
        XCTAssert(baseUrl.contains(cnPath), "error base url \(baseUrl)")

        // 11 num start with 2.
        let sgroomUUID = "2" + String(repeating: "0", count: 10)
        guard let baseUrl = env.customBaseUrlFor(roomUUID: sgroomUUID) else {
            XCTAssert(false, "can't find url")
            return
        }
        XCTAssert(baseUrl.contains(sgPath), "error base url \(baseUrl)")

        // 11 num start with other num
        for n in [0, 3, 4, 5, 6, 7, 8, 9] {
            let roomUUID = n.description + String(repeating: "0", count: 10)
            let customUrl = env.customBaseUrlFor(roomUUID: roomUUID)
            XCTAssert(customUrl == nil, "mismatch base url \(roomUUID), \(env.baseURL), \(String(describing: customUrl))")
        }
        
        // no-all-num start with num
        for n in startRange {
            let roomUUID = n.description + String(repeating: "abc".randomElement()!, count: 23)
            let customUrl = env.customBaseUrlFor(roomUUID: roomUUID)
            XCTAssert(customUrl == nil)
        }
    }
}
