//
//  Array+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/9.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

extension Array where Element: Equatable {
    func removeDuplicate() -> [Element] {
        var new: [Element] = []
        for item in self {
            if !new.contains(item) {
                new.append(item)
            }
        }
        return new
    }
}
