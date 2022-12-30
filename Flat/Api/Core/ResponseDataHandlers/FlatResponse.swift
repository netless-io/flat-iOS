//
//  BaseResponse.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct FlatResponse<T: Decodable>: Decodable {
    let status: Int
    let data: T
}
