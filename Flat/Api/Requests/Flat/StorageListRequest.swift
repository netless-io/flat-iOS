//
//  StorageListRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct StorageListResponse: Decodable {
    let files: [StorageFileModel]
    let totalUsage: Int
}

struct StorageListRequest: FlatRequest {
    struct Input: Encodable {
        let page: Int
        let order: String
        let directoryPath: String
    }
    let page: Int
    
    var path: String { "/v2/cloud-storage/list" }
    var task: Task { .requestJSONEncodable(encodable: Input(page: page, order: "DESC", directoryPath: "/")) }
    let responseType = StorageListResponse.self
}
