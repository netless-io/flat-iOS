//
//  StorageListRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct StorageListResponse: Codable {
    let files: [StorageFileModel]
    let totalUsage: Int
}

struct StorageListRequest: FlatRequest {
    let page: Int
    
    var path: String { "/v1/cloud-storage/list" }
    var task: Task { .requestURLEncodable(parameters: ["page": page])}
    let responseType = StorageListResponse.self
}
