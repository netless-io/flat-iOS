//
//  String+ReguarExpression.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/2.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

extension String {
    func matchExpressionPattern(_ pattern: String) throws -> String? {
        let reg = try NSRegularExpression(pattern: pattern)
        if let result = reg.firstMatch(in: self, range: .init(location: 0, length: count)) {
            let startIndex = index(startIndex, offsetBy: result.range.lowerBound)
            let endIndex = index(startIndex, offsetBy: result.range.length)
            return String(self[startIndex..<endIndex])
        }
        return nil
    }
}
