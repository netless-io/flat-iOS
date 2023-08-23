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
}
