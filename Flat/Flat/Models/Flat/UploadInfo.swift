//
//  UploadInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadInfo: Codable {
    let filePath: String
    let fileUUID: String
    let policy: String
    let policyURL: URL
    let signature: String
}
