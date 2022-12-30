//
//  AgoraRequest.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

protocol AgoraRequest: Request {}

extension AgoraRequest {
    var method: HttpMethod { .post }
    var decoder: JSONDecoder { .agoraDecoder }
}
