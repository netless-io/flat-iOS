//
//  ConvertProgressDetail.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum ConversionTaskType: String, Codable {
    case dynamic
    case `static`
}

struct ConvertedFile: Codable {
    let width: Int
    let height: Int
    let conversionFileUrl: URL
    let preview: URL?
}

struct ConvertProgressDetail: Codable {
    struct ConversionTaskStatus: RawRepresentable, Codable, Equatable {
        static let waiting = ConversionTaskStatus(rawValue: "Waiting")!
        static let converting = ConversionTaskStatus(rawValue: "Converting")!
        static let finished = ConversionTaskStatus(rawValue: "Finished")!
        static let fail = ConversionTaskStatus(rawValue: "Fail")!
        
        var rawValue: String
        init?(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    struct ProgressInfo: Codable {
        let totalPageSize: Int
        let convertedPageSize: Int
        // eg. 30 => 30%
        let convertedPercentage: Int
        // 当前转换任务步骤，只有 type == dynamic 时才有该字段
        let currentStep: String?
        let convertedFileList: [ConvertedFile]
    }
    
    let uuid: String
    let failedReason: String?
    let type: ConversionTaskType
    let status: ConversionTaskStatus
    let progress: ProgressInfo
}
