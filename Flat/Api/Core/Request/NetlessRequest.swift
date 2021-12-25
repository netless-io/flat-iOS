//
//  NetlessRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol NetlessRequest: Request {}

extension NetlessRequest {
    var method: HttpMethod { .get }
    var decoder: JSONDecoder { .netlessDecoder }
}
