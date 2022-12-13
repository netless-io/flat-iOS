//
//  LocaleManager.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct LocaleManager {
    /// "ko-US" → "ko"
    static var languageCode: String? {
        guard var splits = Locale.preferredLanguages.first?.split(separator: "-"), let first = splits.first else { return nil }
        guard splits.count > 1 else { return String(first) }
        splits.removeLast()
        return String(splits.joined(separator: "-"))
    }

    static var language: Language? {
        return Language(languageCode: languageCode)
    }
}
