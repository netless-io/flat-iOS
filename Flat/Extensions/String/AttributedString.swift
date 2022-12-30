//
//  AttributedString.swift
//  Flat
//
//  Created by xuyunshi on 2022/5/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    func add(link: String, forExistString str: String) {
        var r = string[...]

        while let range = r.range(of: str) {
            let l = range.lowerBound.utf16Offset(in: string)
            let h = range.upperBound.utf16Offset(in: string)
            addAttribute(.link, value: link, range: NSRange(location: l, length: h - l))
            r = string[range.upperBound...]
        }
    }
}
