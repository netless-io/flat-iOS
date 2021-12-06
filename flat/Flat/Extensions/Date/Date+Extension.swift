//
//  Date+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/19.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

extension Date {
    func isSameDayTo(_ other: Date) -> Bool {
        Calendar.current.dateComponents([.day], from: self, to: other).day == 0
    }
}
