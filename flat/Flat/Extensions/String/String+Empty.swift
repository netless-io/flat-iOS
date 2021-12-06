//
//  String+Empty.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

extension String {
    var isNotEmptyOrAllSpacing: Bool {
        !isEmptyOrAllSpacing
    }
    
    var isEmptyOrAllSpacing: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
