//
//  Language.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/29985614/how-can-i-change-locale-programmatically-with-swift
enum Language: Equatable, CaseIterable {
    case English
    case Chinese
}

extension Language {
    var code: String {
        switch self {
        case .English: return "en"
        case .Chinese: return "zh-Hans"
        }
    }

    var name: String {
        switch self {
        case .English: return "English"
        case .Chinese: return "简体中文"
        }
    }

    init?(languageCode: String?) {
        guard let languageCode else { return nil }
        switch languageCode {
        case "en": self = .English
        case "zh": self = .Chinese
        case "zh-Hans": self = .Chinese
        default: return nil
        }
    }
}
