//
//  UploadInfo.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct UploadInfo: Codable {
    let fileUUID: String
    let ossFilePath: String
    let ossDomain: URL
    let policy: String
    let signature: String
}
