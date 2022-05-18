//
//  StringLocalize.swift
//  Flat
//
//  Created by xuyunshi on 2022/5/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

func localizeStrings(_ strs: String...)-> String {
    return strs.reduce(into: "") { partialResult, str in
        if LocaleManager.language == .Chinese {
            return partialResult += NSLocalizedString(str, comment: "")
        } else {
            if partialResult.isEmpty {
                return partialResult += NSLocalizedString(str, comment: "")
            } else {
                return partialResult += (" " + NSLocalizedString(str, comment: ""))
            }
        }
    }
}
