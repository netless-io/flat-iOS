//
//  FlatRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol FlatRequest: Request {}

extension FlatRequest {
    var method: HttpMethod { .post }
    var decoder: JSONDecoder { .flatDecoder }
}
