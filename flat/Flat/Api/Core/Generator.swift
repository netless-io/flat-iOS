//
//  Generator.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol Generator {
    func generateRequest<T: Request>(fromApi api: T) throws -> URLRequest
}
