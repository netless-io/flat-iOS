//
//  ApiErrorLocalizeTest.swift
//  Flat_Test
//
//  Created by xuyunshi on 2023/12/12.
//  Copyright © 2023 agora.io. All rights reserved.
//

import XCTest

class ApiErrorLocalizeTest: XCTestCase {
    func testUnlocalizedError() {
        let allErrors = FlatApiError.allCases
            .filter { $0 != .RoomNotBegin && $0 != .RoomNotBeginAndAddList } // Exclude special error.
        let unlocalizedErrors = allErrors.filter { error in
            error.errorDescription == String(describing: error)
        }
        XCTAssertTrue(unlocalizedErrors.isEmpty, "api error not localized: \(unlocalizedErrors)")
    }
}
