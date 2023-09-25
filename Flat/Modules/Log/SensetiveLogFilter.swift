//
//  SensetiveLogFilter.swift
//  Flat
//
//  Created by xuyunshi on 2023/9/25.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

let tokenMatchExpression = try! NSRegularExpression(pattern: "\"token\":\"(.*?)\"")
struct SensetiveLogFilter {
    static func filter(_ input: String) -> String {
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        if let match = tokenMatchExpression.firstMatch(in: input, range: range) {
            if let tokenStringRange = Range(match.range(at: 0), in: input) {
                let matchText = String(input[tokenStringRange])
                return input.replacingOccurrences(of: matchText, with: "\"token\":\"******\"")
            }
        }
        return input
    }
}
